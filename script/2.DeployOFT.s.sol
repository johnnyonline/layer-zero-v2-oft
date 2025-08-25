// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";

import {ASFOFT} from "../src/OFT.sol";

import "forge-std/Script.sol";

// ---- Usage ----

// (2) BASE

// deploy:
// forge script script/2.DeployOFT.s.sol:DeployOFT --verify --slow --legacy --etherscan-api-key $KEY --rpc-url $BASE_RPC_URL --broadcast

contract DeployOFT is Script {
    string public constant NAME = "Asymmetry Finance Token";
    string public constant SYMBOL = "ASF";

    address public constant ENDPOINT = address(0x1a44076050125825900e736c501f859c50fE728c); // Base Mainnet endpointV2
    address public constant DEPLOYER = address(0x6969acca95B7fb9631a114085eEEBd161EC19f25);
    address public constant BASE_SENDULN302 = address(0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2); // SendUln302 Base
    address public constant BASE_RECEIVEULN302 = address(0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf); // ReceiveUln302 Base

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
        // UlnConfig memory uln = UlnConfig({
        //     confirmations: 15, // min block confirmations from source (A)
        //     requiredDVNCount: 2, // required DVNs for message acceptance
        //     optionalDVNCount: type(uint8).max, // optional DVNs count
        //     optionalDVNThreshold: 0, // optional DVN threshold
        //     requiredDVNs: [address(0x1111...), address(0x2222...)], // sorted required DVNs
        //     optionalDVNs: [] // no optional DVNs
        // });

        // bytes memory encodedUln = abi.encode(uln);

        // SetConfigParam[] memory params = new SetConfigParam[](1);
        // params[0] = SetConfigParam(eid, RECEIVE_CONFIG_TYPE, encodedUln);

        // vm.startBroadcast(signer);
        // ILayerZeroEndpointV2(endpoint).setConfig(oapp, receiveLib, params); // Set config for messages received on B from A
        return; // Use default
    }
}
