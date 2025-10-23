// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//privateNet


contract LPToke is ERC20 {
    constructor()
        public
        ERC20("LP TOKE", "LPT")
    {
        _mint(msg.sender, 10000 * 10**uint(decimals()));
    }

    
}