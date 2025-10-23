// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/********************
// STORES CONTRACT ADDRESSES AND SETS THEM IN LINKED CONTRACTS' STORAGE
// Owner interacts with this contract to affect inherited AddressStorage of other contracts 
// (one AddressManager controls many AddressStorage)
// +
********************/

contract AddressStorageInterface{
    function setAddress(string memory _name, address _address) external{}
}

contract AddressManager is Ownable{
  mapping(string => address) public contractAddress;
  AddressStorageInterface addressStorageI;

	constructor()  {
      // junk addresses
      // must be updated after contracts are deployed
      contractAddress['timer'] = 0x0000000000000000000000000000000000000000;
      contractAddress['FLCE'] = 0x0000000000000000000000000000000000000000;
      contractAddress['wolf'] = 0x0000000000000000000000000000000000000000;
      contractAddress['sheep'] = 0x0000000000000000000000000000000000000000;
      contractAddress['pixel'] = 0x0000000000000000000000000000000000000000;
      contractAddress['game'] = 0x0000000000000000000000000000000000000000;
      contractAddress['utilities'] = 0x0000000000000000000000000000000000000000;
    }


    // updates all contracts' locally stored addresses to all current contract addresses
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function pushAllAddresses() public onlyOwner { 
        addressStorageI = AddressStorageInterface(contractAddress['FLCE']);
        addressStorageI.setAddress('game', contractAddress['game']);
        addressStorageI.setAddress('wolf', contractAddress['wolf']);
        addressStorageI.setAddress('timer', contractAddress['timer']);

        addressStorageI = AddressStorageInterface(contractAddress['timer']);
        addressStorageI.setAddress('game', contractAddress['game']);

        addressStorageI = AddressStorageInterface(contractAddress['wolf']);
        addressStorageI.setAddress('FLCE', contractAddress['FLCE']);
        addressStorageI.setAddress('timer', contractAddress['timer']);
        addressStorageI.setAddress('utilities', contractAddress['utilities']);
        addressStorageI.setAddress('game', contractAddress['game']);

        addressStorageI = AddressStorageInterface(contractAddress['utilities']);
        addressStorageI.setAddress('wolf', contractAddress['wolf']);
        addressStorageI.setAddress('game', contractAddress['game']);

        addressStorageI = AddressStorageInterface(contractAddress['game']);
        addressStorageI.setAddress('wolf', contractAddress['wolf']);
        addressStorageI.setAddress('FLCE', contractAddress['FLCE']);
        addressStorageI.setAddress('utilities', contractAddress['utilities']);
        addressStorageI.setAddress('timer', contractAddress['timer']);
        addressStorageI.setAddress('sheep', contractAddress['sheep']);
    }

    // accepts inputed contract name[s] and address[es] and sets them in contracts
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function setAndPush(string[] memory _name, address[] memory _address) public onlyOwner {
      uint256 nameCnt = _name.length;
      uint256 addressCnt = _address.length;
      require(nameCnt == addressCnt, "mismatched array lengths");

      for(uint i=0; i<nameCnt; i++){
        contractAddress[_name[i]] = _address[i];
      }
      pushAllAddresses();
    }

}