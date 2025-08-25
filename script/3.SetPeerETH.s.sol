// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {ASFOFTAdapter} from "../src/OFTAdapter.sol";

// ---- Usage ----

// (3) ETH

// load:
// set vars where @todo

// deploy:
// forge script script/3.SetPeersETH.s.sol:SetPeers --verify --slow --legacy --etherscan-api-key $KEY --rpc-url $ETH_RPC_URL --broadcast

contract SetPeers is Script {
    address public constant OFT_BASE = address(0); // @todo
    address public constant OFT_ADAPTER_ETH = address(0); // @todo

    uint32 public constant BASE_EID = 30184; // Base Mainnet

    function run() external {
        // Load peer
        (uint32 eid1, bytes32 peer1) = (uint32(BASE_EID), bytes32(uint256(uint160(OFT_BASE))));

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Set peer on Base
        ASFOFTAdapter(OFT_ADAPTER_ETH).setPeer(eid1, peer1);

        vm.stopBroadcast();
    }
}
