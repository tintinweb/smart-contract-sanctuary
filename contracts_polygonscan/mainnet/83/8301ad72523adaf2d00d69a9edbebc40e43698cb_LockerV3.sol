// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC1155Holder.sol";

interface IERC20 {
    function transferFrom(
        address sender, address recipient, uint256 amount
    ) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
interface IERC721 {
    function transferFrom(
        address from, address to, uint256 tokenId
    ) external;
}
interface IERC1155 {
    function safeTransferFrom(
        address from, address to, uint256 id, uint256 amount, bytes calldata data
    ) external;
}

contract LockerV3 is ERC1155Holder {
    uint currLockerId;
    
    struct LockerInfo {
        address payable tokenOwner;
        string tokenType;
        address tokenAddress;
        uint tokenId;
        uint tokenAmount;
        uint lockTime;
        uint unlockTime;
        bool isWithdrawn;
    }

    mapping(address => uint[]) locksByUser;
    mapping(uint => LockerInfo) lockerInfoTable;
    event TokenLocked(address user, string indexed tokenType, uint indexed tokenAddress, uint tokenAmount);

    function isEqual(string memory _word1, string memory _word2) private pure returns(bool) {
        return keccak256(bytes(_word1))  == keccak256(bytes(_word2));
    }

    function createLocker(string memory _tokenType, address _tokenAddress, uint _tokenId, uint _tokenAmount, uint _unlockTime) external payable {
        require(_tokenAmount > 0, "05");

        address _tokenOwner = msg.sender;
        if(isEqual(_tokenType, "eth")) {
            require(msg.value == _tokenAmount, "06");
        }
        else if(isEqual(_tokenType, "erc20")) {
            IERC20(_tokenAddress).transferFrom(_tokenOwner, address(this), _tokenAmount);
        }
        else if(isEqual(_tokenType, "erc721")) {
            IERC721(_tokenAddress).transferFrom(_tokenOwner, address(this), _tokenId);
        }
        else if(isEqual(_tokenType, "erc1155")) {
            // bytes memory defaultBytes;
            IERC1155(_tokenAddress).safeTransferFrom(
                _tokenOwner,address(this),_tokenId,_tokenAmount,'0x'
            );
        }
        else {
            require(false, "01");
        }
    
        currLockerId++;
        locksByUser[_tokenOwner].push(currLockerId);
        lockerInfoTable[currLockerId] = LockerInfo(
            payable(_tokenOwner), _tokenType, _tokenAddress, _tokenId, _tokenAmount, 
            block.timestamp, _unlockTime, false
        );
    }

    function getLockerInfo(uint _lockerId) external view returns(LockerInfo memory) {
        return lockerInfoTable[_lockerId];
    }

    function destroyLocker(uint _lockerId) external {
        require(lockerInfoTable[_lockerId].tokenOwner == msg.sender, "02");
        require(lockerInfoTable[_lockerId].unlockTime <= block.timestamp, "03");
        require(lockerInfoTable[_lockerId].isWithdrawn == false, "04");

        string memory tokenType = lockerInfoTable[_lockerId].tokenType;
        address payable tokenOwner = lockerInfoTable[_lockerId].tokenOwner;
        address tokenAddress = lockerInfoTable[_lockerId].tokenAddress;
        uint tokenId = lockerInfoTable[_lockerId].tokenId;
        uint tokenAmount = lockerInfoTable[_lockerId].tokenAmount;
        if(isEqual(tokenType, "eth")) {
            tokenOwner.transfer(tokenAmount);
        }
        else if(isEqual(tokenType, "erc20")) {
            IERC20(tokenAddress).transfer(tokenOwner, tokenAmount);
        }
        else if(isEqual(tokenType, "erc721")) {
            IERC721(tokenAddress).transferFrom(address(this), tokenOwner, tokenId);
        }
        else if(isEqual(tokenType, "erc1155")) {
            // bytes memory defaultBytes;
            IERC1155(tokenAddress).safeTransferFrom(
                address(this),tokenOwner,tokenId,tokenAmount,'0x'
            );
        }

        uint totalLocks = locksByUser[tokenOwner].length;
        for(uint i=0; i<totalLocks; i++) {
            if(locksByUser[tokenOwner][i] == _lockerId) {
                // replace current lockerId with last lockerId
                locksByUser[tokenOwner][i] = locksByUser[tokenOwner][totalLocks-1];
                break;
            }
        }
        locksByUser[tokenOwner].pop();   // remove last lockerId
        lockerInfoTable[_lockerId].isWithdrawn = true;
    }

    function getLockersOfUser(address _tokenOwner) external view returns(uint[] memory) {
        return locksByUser[_tokenOwner];
    }
}