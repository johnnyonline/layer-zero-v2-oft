// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import {ASFOFTAdapter} from "../src/OFTAdapter.sol";

import "forge-std/Script.sol";

// ---- Usage ----

// (1) ETH

// deploy:
// forge script script/1.DeployOFTAdapter.s.sol:DeployOFTAdapter --verify --slow --legacy --etherscan-api-key $KEY --rpc-url $ETH_RPC_URL --broadcast

contract DeployOFTAdapter is Script {
    using OptionsBuilder for bytes;

    address public constant ASF = address(0x59a529070fBb61e6D6c91f952CcB7f35c34Cf8Aa); // ASF Mainnet
    address public constant ENDPOINT = address(0x1a44076050125825900e736c501f859c50fE728c); // Ethereum Mainnet endpointV2
    address public constant DEPLOYER = address(0x6969acca95B7fb9631a114085eEEBd161EC19f25); // asym deployer
    address public constant ETH_SENDULN302 = address(0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1); // SendUln302 Ethereum
    address public constant ETH_RECEIVEULN302 = address(0xc02Ab410f0734EFa3F14628780e6e695156024C2); // ReceiveUln302 Ethereum
    address public constant ETH_CANARY_DVN = address(0xa4fE5A5B9A846458a70Cd0748228aED3bF65c2cd); // Ethereum Canary DVN
    address public constant ETH_DEUTCHE_DVN = address(0x373a6E5c0C4E89E24819f00AA37ea370917AAfF4); // Ethereum Deutsche Telekom DVN
    address public constant ETH_LUGANODES_DVN = address(0x58249a2Ec05c1978bF21DF1f5eC1847e42455CF4); // Ethereum Luganodes DVN
    address public constant ETH_LZ_EXECUTOR = address(0x173272739Bd7Aa6e4e214714048a9fE699453059); // LZ Executor ethereum

    uint16 SEND = 1;  // Message type for sendString function
    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;
    uint32 public constant BASE_EID = 30184; // Base Mainnet
    uint32 public constant ETH_EID = 30101; // Ethereum Mainnet
    uint256 public constant GRACE_PERIOD = 0;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy OFTAdapter
        address _oftAdapter = _deployOFTAdapter();

        // Set libraries
        _setLibraries(_oftAdapter);

        // Set send config
        _setSendConfig(_oftAdapter);

        // Set enforced options
        _setEnforcedOptions(_oftAdapter);

        vm.stopBroadcast();

        console.log("OFT Adapter deployed to:", _oftAdapter);
    }

    function _deployOFTAdapter() internal returns (address) {
        return address(new ASFOFTAdapter(ASF, ENDPOINT, DEPLOYER));
    }

    function _setLibraries(address _oftAdapter) internal {
        // Set send library for outbound messages
        ILayerZeroEndpointV2(ENDPOINT).setSendLibrary(
            _oftAdapter, // OApp address
            BASE_EID, // Destination chain EID
            ETH_SENDULN302 // SendUln302 address
        );

        // Set receive library for inbound messages
        ILayerZeroEndpointV2(ENDPOINT).setReceiveLibrary(
            _oftAdapter, // OApp address
            ETH_EID, // Source chain EID
            ETH_RECEIVEULN302, // ReceiveUln302 address
            GRACE_PERIOD // Grace period for library switch
        );
    }

    function _setSendConfig(address _oftAdapter) internal {
        address[] memory requiredDVNs = new address[](0);
        address[] memory optionalDVNs = new address[](3);
        optionalDVNs[0] = ETH_DEUTCHE_DVN;
        optionalDVNs[1] = ETH_LUGANODES_DVN;
        optionalDVNs[2] = ETH_CANARY_DVN;
        UlnConfig memory uln = UlnConfig({
            confirmations: 15, // minimum block confirmations required on A before sending to B
            requiredDVNCount: 0, // number of DVNs required
            optionalDVNCount: 3, // optional DVNs count, uint8
            optionalDVNThreshold: 2, // optional DVN threshold
            requiredDVNs: requiredDVNs, // sorted list of required DVN addresses
            optionalDVNs: optionalDVNs // sorted list of optional DVNs
        });

        ExecutorConfig memory exec = ExecutorConfig({
            maxMessageSize: 10000, // max bytes per cross-chain message
            executor: ETH_LZ_EXECUTOR // address that pays destination execution fees on B
        });

        bytes memory encodedUln  = abi.encode(uln);
        bytes memory encodedExec = abi.encode(exec);

        SetConfigParam[] memory params = new SetConfigParam[](2);
        params[0] = SetConfigParam(BASE_EID, EXECUTOR_CONFIG_TYPE, encodedExec);
        params[1] = SetConfigParam(BASE_EID, ULN_CONFIG_TYPE, encodedUln);

        // Set config for messages sent from A to B
        ILayerZeroEndpointV2(ENDPOINT).setConfig(_oftAdapter, ETH_SENDULN302, params);
    }

    function _setEnforcedOptions(address _oftAdapter) internal {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(100000, 0);

        // Create enforced options array
        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);

        // Set enforced options for first destination
        enforcedOptions[0] = EnforcedOptionParam({
            eid: BASE_EID,
            msgType: SEND,
            options: options
        });

        // Set enforced options on the OApp
        ASFOFTAdapter(_oftAdapter).setEnforcedOptions(enforcedOptions);
    }
}
