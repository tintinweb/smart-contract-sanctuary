// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";
import "SafeMath.sol";

interface Randomized {
    function CID_by_ID(uint256 token_ID) external view returns (bytes memory);
}

contract Anonz is ERC721, Ownable {
    uint256 MAX_ID = 7000; //7000 ANZ NFT's, not 6999, not 7001
    bool lootery_active;
    bool revealed;
    Randomized contract_CID_randomized;
    bytes internal constant _ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"; //just a kind reminder to our readers.
    string contract_URI_shop;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using SafeMath for uint256;

    constructor() ERC721("ANZ", "Anonz") {
        lootery_active=true;
        revealed=false;
        _setBaseURI("https://ipfs.io/ipfs/");
        contract_URI_shop = "https://ipfs.io/ipfs/Qmbqp5hr2i3ug14V7EyR9PYjCSzKnQ272NyT4pTcqkTrGs";
        }

    function current_price() public view returns (uint256) {
        uint256 current_ID = _tokenIds.current();
        require(current_ID <= MAX_ID, "No more ANZ to mint");

        //the "Carl" pricing function
        if (current_ID >= 6300) {
            return 100000000000000000;
        } else if (current_ID >= 5600) {
            return 260000000000000000;
        } else if (current_ID >= 4900) {
            return 390000000000000000;
        } else if (current_ID >= 4200) {
            return 640000000000000000;
        } else if (current_ID >= 3500) {
            return 900000000000000000;
        } else if (current_ID >= 2100) {
            return 640000000000000000;
        } else if (current_ID >= 1400) {
            return 390000000000000000;
        } else if (current_ID >= 700) {
            return 260000000000000000;
        } else {
            return 100000000000000000;
        }
    }

    function mintNFT(address receiver, uint256 nb_nft) external payable {
        require(nb_nft > 0, "cannot buy 0 ANZ");
        require(nb_nft <= 40, "max 40 NFTs can be minted at a time");
        require(current_price().mul(nb_nft) <= msg.value, "not enough ETH sent");
        require(_tokenIds.current().add(nb_nft) <= MAX_ID, "not enought ANZ left to mint");

        uint256 value_sent = msg.value;

        for (uint i = 0; i < nb_nft; i++) {
            require(value_sent >= current_price(), "not enough ETH sent for full tx"); //price changing in the middle of a lot?
            value_sent = value_sent.sub(current_price());
            _tokenIds.increment();
            _mint(receiver, _tokenIds.current());
        }
    }

    //set the contract where randomized URI are and prevent further change of it
    function set_URI(address rand_contract) public onlyOwner {
        require(revealed==false, "anonz already revealed, no more change allowed");
        contract_CID_randomized = Randomized(rand_contract);
        revealed=true;
    }

    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "This anonz has not been minted yet");
        if (revealed == true){
            bytes memory hash_bytes = contract_CID_randomized.CID_by_ID(token_id);
            string memory hash = _toBase58(hash_bytes);
            return string(abi.encodePacked(baseURI(), hash));
        }
        else {
            return "https://ipfs.io/ipfs/QmThsKQpFBQicz3t3SU9rRz3GV81cwjnWsBBLxzznRNvpn";
            //default URI before the Great Reveal Day - pinned
        }
    }

    function setContractUriShop(string memory new_contract_uri) public onlyOwner {
        contract_URI_shop = new_contract_uri;
    }

    function contractURI() public view returns (string memory) {
        return contract_URI_shop;
    }


    function lootery(address payable winner1, address payable winner2) external onlyOwner {
      require(lootery_active, "lootery is already finished");
      uint256 reward = address(this).balance.div(20);
      lootery_active = false;
      winner1.transfer(reward); //onlyOwner and bool test, ergo no reentrance from winner1, right? ...right?!
      winner2.transfer(reward);
    }


    function withdraw() onlyOwner public {
      uint256 balance = address(this).balance;
      msg.sender.transfer(balance);
    }

    //the _toBase58 consume a lot of gaz when called from another contract. Therefore, calling tokenURI from a contract might fail
    //(no worries for us, view & pure functions are "free" for humans)

    // Source: verifyIPFS (https://github.com/MrChico/verifyIPFS/blob/master/contracts/verifyIPFS.sol)
    // @author Martin Lundfall ([email protected])
    // @dev Converts hex string to base 58
    function _toBase58(bytes memory source)
        internal
        pure
        returns (string memory)
    {
        if (source.length == 0) return new string(0);
        uint8[] memory digits = new uint8[](46);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return string(_toAlphabet(_reverse(_truncate(digits, digitlength))));
    }

    function _truncate(uint8[] memory array, uint8 length)
        internal
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function _reverse(uint8[] memory input)
        internal
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function _toAlphabet(uint8[] memory indices)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = _ALPHABET[indices[i]];
        }
        return output;
    }

}