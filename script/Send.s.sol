// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ASFOFTAdapter} from "../src/OFTAdapter.sol";
import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

// ---- Usage ----

// deploy:
// forge script script/Send.s.sol:SendOFT --slow --legacy --etherscan-api-key $KEY --rpc-url $ETH_RPC_URL --broadcast

contract SendOFT is Script {
    using OptionsBuilder for bytes;

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function run() external {
        // Load environment variables
        address asf = 0x59a529070fBb61e6D6c91f952CcB7f35c34Cf8Aa;
        address oftAddress = 0x4FeB6c50a69D0Cb29F77E307249C767607b04408;
        address toAddress = 0x6969acca95B7fb9631a114085eEEBd161EC19f25;
        uint256 tokensToSend = 3 ether; // 3 ASF
        uint32 dstEid = 30184;

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        IERC20(asf).approve(oftAddress, tokensToSend);

        ASFOFTAdapter oft = ASFOFTAdapter(oftAddress);

        // Build send parameters
        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(65000, 0);
        SendParam memory sendParam = SendParam({
            dstEid: dstEid,
            to: addressToBytes32(toAddress),
            amountLD: tokensToSend,
            minAmountLD: tokensToSend * 95 / 100, // 5% slippage tolerance
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });

        // Get fee quote
        MessagingFee memory fee = oft.quoteSend(sendParam, false);

        console.log("Sending tokens...");
        console.log("Fee amount:", fee.nativeFee);

        // Send tokens
        oft.send{value: fee.nativeFee}(sendParam, fee, msg.sender);

        vm.stopBroadcast();
    }
}