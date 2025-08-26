// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {ASFOFTAdapter} from "../src/OFTAdapter.sol";

// ---- Usage ----

// (4) Base

// load:
// set vars where @todo

// deploy:
// forge script script/4.SetPeerBASE.s.sol:SetPeers --verify --slow --legacy --etherscan-api-key $KEY --rpc-url $BASE_RPC_URL --broadcast

contract SetPeers is Script {
    address public constant OFT_BASE = address(0x7543e3829eCDd61a5fD7c187ff88c4cf46E30F73);
    address public constant OFT_ADAPTER_ETH = address(0x4FeB6c50a69D0Cb29F77E307249C767607b04408);

    uint32 public constant ETH_EID = 30101; // Ethereum Mainnet

    function run() external {
        // Load peer
        (uint32 eid1, bytes32 peer1) = (uint32(ETH_EID), bytes32(uint256(uint160(OFT_ADAPTER_ETH))));

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Set peer on Base
        ASFOFTAdapter(OFT_BASE).setPeer(eid1, peer1);

        vm.stopBroadcast();
    }
}
