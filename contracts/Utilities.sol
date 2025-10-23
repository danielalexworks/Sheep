// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./AddressStorage.sol";

contract Utilities is AddressStorage{

	constructor()  {   
    }

    // pad token name with leading zeros to match file names
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function pad(uint256 _n) external pure returns(string memory){
        string memory t;
        string memory z = "0";
        if (_n < 1000){
            if (_n < 10){
                t = string(abi.encodePacked(z, z, z, Strings.toString(_n)));
            }else if(_n<100){
                t = string(abi.encodePacked(z, z, Strings.toString(_n)));
            }else{
                t = string(abi.encodePacked(z, Strings.toString(_n)));
            }
        }else{
            t = Strings.toString(_n);
        }
        return t;
    }
}