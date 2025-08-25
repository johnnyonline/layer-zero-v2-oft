// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ASFOFT is OFT {
    constructor(string memory _name, string memory _symbol, address _lzEndpoint, address _owner)
        OFT(_name, _symbol, _lzEndpoint, _owner)
        Ownable(_owner)
    {}
}
