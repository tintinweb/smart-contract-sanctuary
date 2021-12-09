/**
 *Submitted for verification at BscScan.com on 2021-12-09
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
        address wallet;
        uint256 itype;
    }

    struct DeleteTag {
        string key;
        uint256 itype;
    }

    struct BnsInfo {
        mapping(string=>uint256) chainMap;
        string[] chainList;
        address[] walletList;
        mapping(string=>uint256) textMap;
        string[] nameList;
        string[] textList;
    }
    mapping(uint256 => BnsInfo) private infoMap;
    address public _punkAddress = 0x64cA2921843929022E677978F08D9B325C802980;

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
            if (item.itype == 1) {
                BnsInfo storage itemInfo = infoMap[nftId];
                if (itemInfo.chainMap[item.key] > 0) {
                    uint256 pos = itemInfo.chainMap[item.key];
                    itemInfo.walletList[pos] = item.wallet;
                }else {
                    itemInfo.chainMap[item.key] = itemInfo.walletList.length;
                    itemInfo.walletList.push(item.wallet);
                    itemInfo.chainList.push(item.key);
                }
            }else {
                BnsInfo storage itemInfo = infoMap[nftId];
                if (itemInfo.textMap[item.key] > 0) {
                    uint256 pos = itemInfo.textMap[item.key];
                    itemInfo.textList[pos] = item.text;
                }else {
                    itemInfo.textMap[item.key] = itemInfo.textList.length;
                    itemInfo.textList.push(item.text);
                    itemInfo.nameList.push(item.key);
                }
            }
        }
    }

    function deleteBatch(uint256 nftId, DeleteTag[] memory list) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        require(list.length > 0, "list can not be empty");

        for (uint i = 0; i < list.length; i++) {
            DeleteTag memory item = list[i];
            if (item.itype == 1) {
                BnsInfo storage itemInfo = infoMap[nftId];
                uint256 pos = itemInfo.textMap[item.key];
                itemInfo.textList[pos] = "";
                itemInfo.textMap[item.key] = 0;
            }else {
                BnsInfo storage itemInfo = infoMap[nftId];
                uint256 pos = itemInfo.textMap[item.key];
                itemInfo.textList[pos] = "";
                itemInfo.textMap[item.key] = 0;
            }
        }
    }

    function deleteText(uint256 nftId, string memory keyName) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        
        BnsInfo storage itemInfo = infoMap[nftId];
        uint256 pos = itemInfo.textMap[keyName];
        itemInfo.textList[pos] = "";
        itemInfo.textMap[keyName] = 0;
    }

    function deleteWallet(uint256 nftId, string memory chainName) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");

        BnsInfo storage itemInfo = infoMap[nftId];
        uint256 pos = itemInfo.chainMap[chainName];
        itemInfo.walletList[pos] = address(0);
        itemInfo.chainMap[chainName] = 0;
    }

    function setWallet(uint256 nftId, string memory chainName, address wallet) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        BnsInfo storage itemInfo = infoMap[nftId];
        if (itemInfo.chainMap[chainName] > 0) {
            uint256 pos = itemInfo.chainMap[chainName];
            itemInfo.walletList[pos] = wallet;
        }else {
            itemInfo.chainMap[chainName] = itemInfo.walletList.length;
            itemInfo.walletList.push(wallet);
            itemInfo.chainList.push(chainName);
        }
    }

    function setTextItem(uint256 nftId, string memory keyName, string memory textInfo) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");

        BnsInfo storage itemInfo = infoMap[nftId];
        if (itemInfo.textMap[keyName] > 0) {
            uint256 pos = itemInfo.textMap[keyName];
            itemInfo.textList[pos] = textInfo;
        }else {
            itemInfo.textMap[keyName] = itemInfo.textList.length;
            itemInfo.textList.push(textInfo);
            itemInfo.nameList.push(keyName);
        }
    }

    function getNftTextInfo(uint256 nftId) public view returns(string[] memory nameList, string[] memory textList) {
        return (infoMap[nftId].nameList, infoMap[nftId].textList);
    }

    function getNftWallet(uint256 nftId) public view returns(string[] memory chainList, 
        address[] memory walletList) {
        return (infoMap[nftId].chainList, infoMap[nftId].walletList);
    }
}