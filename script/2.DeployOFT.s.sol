// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import {ASFOFT} from "../src/OFT.sol";

import "forge-std/Script.sol";

// ---- Usage ----

// (2) BASE

// deploy:
// forge script script/2.DeployOFT.s.sol:DeployOFT --verify --slow --legacy --etherscan-api-key $KEY --rpc-url $BASE_RPC_URL --broadcast

contract DeployOFT is Script {
    using OptionsBuilder for bytes;

    string public constant NAME = "Asymmetry Finance Token";
    string public constant SYMBOL = "ASF";

    address public constant ENDPOINT = address(0x1a44076050125825900e736c501f859c50fE728c); // Base Mainnet endpointV2
    address public constant DEPLOYER = address(0x6969acca95B7fb9631a114085eEEBd161EC19f25);
    address public constant BASE_SENDULN302 = address(0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2); // SendUln302 Base
    address public constant BASE_RECEIVEULN302 = address(0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf); // ReceiveUln302 Base
    address public constant BASE_CANARY_DVN = address(0x554833698Ae0FB22ECC90B01222903fD62CA4B47); // Base Canary DVN
    address public constant BASE_DEUTCHE_DVN = address(0xc2A0C36f5939A14966705c7Cec813163FaEEa1F0); // Base Deutsche Telekom DVN
    address public constant BASE_LUGANODES_DVN = address(0xa0AF56164F02bDf9d75287ee77c568889F11d5f2); // Base Luganodes DVN
    address public constant ETH_LZ_EXECUTOR = address(0x173272739Bd7Aa6e4e214714048a9fE699453059); // LZ Executor ethereum

    uint16 SEND = 1;  // Message type for sendString function
    uint32 constant RECEIVE_CONFIG_TYPE = 2;
    uint32 public constant BASE_EID = 30184; // Base Mainnet
    uint32 public constant ETH_EID = 30101; // Ethereum Mainnet
    uint256 public constant GRACE_PERIOD = 0;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy OFT
        address _oft = _deployOFT();

        // Set libraries
        _setLibraries(_oft);

        // Set receive config
        _setReceiveConfig(_oft);

        // Set enforced options
        _setEnforcedOptions(_oft);

        vm.stopBroadcast();

        console.log("OFT deployed to:", address(_oft));
    }

    function _deployOFT() internal returns (address) {
        return address(new ASFOFT(NAME, SYMBOL, ENDPOINT, DEPLOYER));
    }

    function _setLibraries(address _oft) internal {
        // Set send library for outbound messages
        ILayerZeroEndpointV2(ENDPOINT).setSendLibrary(
            _oft, // OApp address
            ETH_EID, // Destination chain EID
            BASE_SENDULN302 // SendUln302 address
        );

        // Set receive library for inbound messages
        ILayerZeroEndpointV2(ENDPOINT).setReceiveLibrary(
            _oft, // OApp address
            BASE_EID, // Source chain EID
            BASE_RECEIVEULN302, // ReceiveUln302 address
            GRACE_PERIOD // Grace period for library switch
        );
    }

    function _setReceiveConfig(address _oft) internal {
        address[] memory requiredDVNs = new address[](0);
        address[] memory optionalDVNs = new address[](3);
        optionalDVNs[0] = BASE_CANARY_DVN;
        optionalDVNs[1] = BASE_LUGANODES_DVN;
        optionalDVNs[2] = BASE_DEUTCHE_DVN;
        UlnConfig memory uln = UlnConfig({
            confirmations: 15, // min block confirmations from source (A)
            requiredDVNCount: 0, // required DVNs for message acceptance
            optionalDVNCount: 3, // optional DVNs count
            optionalDVNThreshold: 2, // optional DVN threshold
            requiredDVNs: requiredDVNs, // sorted required DVNs
            optionalDVNs: optionalDVNs // sorted optional DVNs
        });

        bytes memory encodedUln = abi.encode(uln);

        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam(ETH_EID, RECEIVE_CONFIG_TYPE, encodedUln);

        ILayerZeroEndpointV2(ENDPOINT).setConfig(_oft, BASE_RECEIVEULN302, params); // Set config for messages received on B from A
    }

    function _setEnforcedOptions(address _oft) internal {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(100000, 0);

        // Create enforced options array
        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);

        // Set enforced options for first destination
        enforcedOptions[0] = EnforcedOptionParam({
            eid: ETH_EID,
            msgType: SEND,
            options: options
        });

        // Set enforced options on the OApp
        ASFOFT(_oft).setEnforcedOptions(enforcedOptions);
    }
}
