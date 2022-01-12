/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
      address private _owner;

      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

      /**
       * @dev Initializes the contract setting the deployer as the initial owner.
       */
      constructor () internal {
          address msgSender = _msgSender();
          _owner = msgSender;
          emit OwnershipTransferred(address(0), msgSender);
      }

      /**
       * @dev Returns the address of the current owner.
       */
      function owner() public view returns (address) {
          return _owner;
      }

      /**
       * @dev Throws if called by any account other than the owner.
       */
      modifier onlyOwner() {
          require(_owner == _msgSender(), "Ownable: caller is not the owner");
          _;
      }

      /**
       * @dev Leaves the contract without owner. It will not be possible to call
       * `onlyOwner` functions anymore. Can only be called by the current owner.
       *
       * NOTE: Renouncing ownership will leave the contract without an owner,
       * thereby removing any functionality that is only available to the owner.
       */
      function renounceOwnership() public virtual onlyOwner {
          emit OwnershipTransferred(_owner, address(0));
          _owner = address(0);
      }

      /**
       * @dev Transfers ownership of the contract to a new account (`newOwner`).
       * Can only be called by the current owner.
       */
      function transferOwnership(address newOwner) public virtual onlyOwner {
          require(newOwner != address(0), "Ownable: new owner is the zero address");
          emit OwnershipTransferred(_owner, newOwner);
          _owner = newOwner;
      }
}

interface IMasks {
    function ownerOf(uint256 index) external view returns (address);
}

contract Parse is Ownable {
    struct Single {
        string key;
        string text;
        string wallet;
        uint256 itype;
    }

    struct DeleteTag {
        string key;
        uint256 itype;
    }

    struct BnsInfo {
        mapping(string=>uint256) chainMap;
        string[] chainList;
        string[] walletList;
        mapping(string=>uint256) textMap;
        string[] nameList;
        string[] textList;
    }
    mapping(uint256 => BnsInfo) private infoMap;
    address public _punkAddress = 0xE1A19A88e0bE0AbBfafa3CaE699Ad349717CA7F2;
    
    event SetSingle(uint256 nftId, string key, string value, uint256 itype);
    event SetBatch(uint256 nftId, Single[] list);
    event DeleteSingle(uint256 nftId, string key, uint256 itype);
    event DeleteBatch(uint256 nftId, DeleteTag[] list);

    function setPunkContract(address punk) public onlyOwner {
        _punkAddress = punk;
    }

    function getOwner(uint256 nftId) public view returns(address) {
        return IMasks(_punkAddress).ownerOf(nftId);
    }

    function setBatchInfo(uint256 nftId,Single[] memory list) public {
        require(list.length > 0, "list can not be empty");
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");

        for (uint i = 0; i < list.length; i++) {
            Single memory item = list[i];
            string memory key = toLower(item.key);
            if (item.itype == 1) {
                BnsInfo storage itemInfo = infoMap[nftId];
                if (itemInfo.chainMap[key] > 0) {
                    uint256 pos = itemInfo.chainMap[key]-1;
                    itemInfo.walletList[pos] = item.wallet;
                }else {
                    itemInfo.chainMap[key] = itemInfo.walletList.length+1;
                    itemInfo.walletList.push(item.wallet);
                    itemInfo.chainList.push(key);
                }
            }else {
                BnsInfo storage itemInfo = infoMap[nftId];
                if (itemInfo.textMap[key] > 0) {
                    uint256 pos = itemInfo.textMap[key]-1;
                    itemInfo.textList[pos] = item.text;
                }else {
                    itemInfo.textMap[key] = itemInfo.textList.length+1;
                    itemInfo.textList.push(item.text);
                    itemInfo.nameList.push(key);
                }
            }
        }
        emit SetBatch(nftId, list);
    }

    function deleteBatch(uint256 nftId, DeleteTag[] memory list) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        require(list.length > 0, "list can not be empty");

        for (uint i = 0; i < list.length; i++) {
            DeleteTag memory item = list[i];
            string memory key = toLower(item.key);
            if (item.itype == 1) {
                BnsInfo storage itemInfo = infoMap[nftId];
                uint256 pos = itemInfo.textMap[key]-1;
                itemInfo.textList[pos] = "";
                itemInfo.textMap[key] = 0;
            }else {
                BnsInfo storage itemInfo = infoMap[nftId];
                uint256 pos = itemInfo.textMap[key]-1;
                itemInfo.textList[pos] = "";
                itemInfo.textMap[key] = 0;
            }
        }

        emit DeleteBatch(nftId, list);
    }

    function deleteText(uint256 nftId, string memory keyName) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        
        keyName = toLower(keyName);
        BnsInfo storage itemInfo = infoMap[nftId];
        uint256 pos = itemInfo.textMap[keyName]-1;
        itemInfo.textList[pos] = "";
        itemInfo.textMap[keyName] = 0;

        emit DeleteSingle(nftId, keyName, 2);
    }

    function deleteWallet(uint256 nftId, string memory chainName) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");

        chainName = toLower(chainName);
        BnsInfo storage itemInfo = infoMap[nftId];
        uint256 pos = itemInfo.chainMap[chainName]-1;
        itemInfo.walletList[pos] = "";
        itemInfo.chainMap[chainName] = 0;

        emit DeleteSingle(nftId, chainName, 1);
    }

    function setWallet(uint256 nftId, string memory chainName, string memory wallet) public returns(uint256) {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        BnsInfo storage itemInfo = infoMap[nftId];
        chainName = toLower(chainName);
        if (itemInfo.chainMap[chainName] > 0) {
            uint256 pos = itemInfo.chainMap[chainName]-1;
            itemInfo.walletList[pos] = wallet;
        }else {
            itemInfo.chainMap[chainName] = itemInfo.walletList.length+1;
            itemInfo.walletList.push(wallet);
            itemInfo.chainList.push(chainName);
        }

        emit SetSingle(nftId, chainName, wallet, 1);
        return itemInfo.chainMap[chainName];
    }

    function setTextItem(uint256 nftId, string memory keyName, string memory textInfo) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");

        BnsInfo storage itemInfo = infoMap[nftId];
        keyName = toLower(keyName);
        if (itemInfo.textMap[keyName] > 0) {
            uint256 pos = itemInfo.textMap[keyName]-1;
            itemInfo.textList[pos] = textInfo;
        }else {
            itemInfo.textMap[keyName] = itemInfo.textList.length+1;
            itemInfo.textList.push(textInfo);
            itemInfo.nameList.push(keyName);
        }

        emit SetSingle(nftId, keyName, textInfo, 2);
    }

    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function getNftTextInfo(uint256 nftId) public view returns(string[] memory nameList, string[] memory textList) {
        return (infoMap[nftId].nameList, infoMap[nftId].textList);
    }

    function getNftWallet(uint256 nftId) public view returns(string[] memory chainList, 
        string[] memory walletList) {
        return (infoMap[nftId].chainList, infoMap[nftId].walletList);
    }
}