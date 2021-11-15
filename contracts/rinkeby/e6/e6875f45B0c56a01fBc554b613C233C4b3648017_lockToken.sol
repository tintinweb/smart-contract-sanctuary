// SPDX-License-Identifier: MIT

pragma solidity ^0.4.25;

/**
 * Team Token Lockup
*/

contract Token {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ERC721Token {
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from, address to, uint256 tokenId
    ) external;
    function transferFrom(
        address from, address to, uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from, address to, uint256 tokenId, bytes data
    ) external;
}


interface ERC1155Token {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] accounts, uint256[] ids)
        external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);  
    function safeTransferFrom(
        address from, address to, uint256 id, uint256 amount, bytes data
    ) external;
    function safeBatchTransferFrom(
        address from, address to, uint256[] ids, uint256[] amounts, bytes data
    ) external;
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
}

contract lockToken is owned {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }
    
    using SafeMath for uint256;
    
    /*
     * deposit vars
    */
    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }
    
    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping (address => uint256[]) public depositsByWithdrawalAddress;
    mapping (uint256 => Items) public lockedToken;
    mapping (address => mapping(address => uint256)) public walletTokenBalance;
    
    event LogWithdrawal(address SentToAddress, uint256 AmountTransferred);

        
    /**
     * Constrctor function
    */
    constructor() public {
        
    }
    
    /**
     *lock tokens
    */
    function lockTokens(address _tokenAddress, uint256 _amount, uint256 _unlockTime) public returns (uint256 _id) {
        require(_amount > 0, 'token amount is Zero');
        require(_unlockTime < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
        require(Token(_tokenAddress).approve(this, _amount), 'Approve tokens failed');
        require(Token(_tokenAddress).transferFrom(msg.sender, this, _amount), 'Transfer of tokens failed');
        
        //update balance in address
        walletTokenBalance[_tokenAddress][msg.sender] = walletTokenBalance[_tokenAddress][msg.sender].add(_amount);
        
        address _withdrawalAddress = msg.sender;
        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = _amount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;
        
        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
    }
    
    
    
    struct ERC721Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenId;
        uint256 unlockTime;
        bool withdrawn;
    }
    mapping(uint256 => ERC721Items) public ERC721Locker;
    mapping(address => mapping(address => uint256)) public walletERC721Balance;
    event LogERC721Withdrawal(address SentToAddress, uint256 TokenId);
    
    function lockERC721Tokens(address _tokenAddress, uint256 _tokenId, uint256 _unlockTime) public returns (uint256 _id) {
        require(_unlockTime < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
        // approval should be already given
        ERC721Token(_tokenAddress).transferFrom(msg.sender, this, _tokenId);
        
        //update balance in address
        walletERC721Balance[_tokenAddress][msg.sender] = walletERC721Balance[_tokenAddress][msg.sender].add(1);
        
        address _withdrawalAddress = msg.sender;
        _id = ++depositId;
        ERC721Locker[_id].tokenAddress = _tokenAddress;
        ERC721Locker[_id].withdrawalAddress = _withdrawalAddress;
        ERC721Locker[_id].tokenId = _tokenId;
        ERC721Locker[_id].unlockTime = _unlockTime;
        ERC721Locker[_id].withdrawn = false;
        
        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
    }
    
    
    
    struct ERC1155Items {
        address tokenAddress;
        address withdrawalAddress;
        uint tokenId;
        uint tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }
    mapping(uint256 => ERC1155Items) public ERC1155Locker;
    mapping(address => mapping(address => uint256)) public walletERC1155Balance;
    
    function lockERC1155Tokens(address _tokenAddress, uint256 _tokenId, uint256 _tokenAmount, uint256 _unlockTime) public returns (uint256 _id) {
        require(_unlockTime < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
        require(_tokenAmount > 0, 'number of tokens must be >0');
        // approval should be already given
        
        
        ERC1155Token(_tokenAddress).safeTransferFrom(
            msg.sender, this, _tokenId, _tokenAmount, abi.encodePacked(_tokenAddress)
        );
        
        //update balance in address
        walletERC1155Balance[_tokenAddress][msg.sender] = walletERC1155Balance[_tokenAddress][msg.sender].add(_tokenAmount);
        
        address _withdrawalAddress = msg.sender;
        _id = ++depositId;
        ERC1155Locker[_id].tokenAddress = _tokenAddress;
        ERC1155Locker[_id].withdrawalAddress = _withdrawalAddress;
        ERC1155Locker[_id].tokenId = _tokenId;
        ERC1155Locker[_id].tokenAmount = _tokenAmount;
        ERC1155Locker[_id].unlockTime = _unlockTime;
        ERC1155Locker[_id].withdrawn = false;
        
        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
    }
    
    /**
     *withdraw tokens
    */
    function withdrawTokens(uint256 _id) public {
        require(block.timestamp >= lockedToken[_id].unlockTime, 'Tokens are locked');
        require(msg.sender == lockedToken[_id].withdrawalAddress, 'Can withdraw by withdrawal Address only');
        require(!lockedToken[_id].withdrawn, 'Tokens already withdrawn');
        require(Token(lockedToken[_id].tokenAddress).transfer(msg.sender, lockedToken[_id].tokenAmount), 'Transfer of tokens failed');
        
        lockedToken[_id].withdrawn = true;
        
        //update balance in address
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(lockedToken[_id].tokenAmount);
        
        //remove this id from this address
        uint256 i; uint256 j;
        for(j=0; j<depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length; j++){
            if(depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id){
                for (i = j; i<depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length-1; i++){
                    depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][i] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][i+1];
                }
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length--;
                break;
            }
        }
        emit LogWithdrawal(msg.sender, lockedToken[_id].tokenAmount);
    }
    
    
    
    
    function withdrawERC721Tokens(uint256 _id) public {
        require(block.timestamp >= ERC721Locker[_id].unlockTime, 'Unlock time is still in future');
        require(msg.sender == ERC721Locker[_id].withdrawalAddress, 'Can withdraw by withdrawal Address only');
        require(!ERC721Locker[_id].withdrawn, 'ERC721Token already withdrawn');
        uint _tokenId = ERC721Locker[_id].tokenId;
        address _tokenAddress = ERC721Locker[_id].tokenAddress;
        ERC721Token(_tokenAddress).transferFrom(this, msg.sender, _tokenId);
        
        ERC721Locker[_id].withdrawn = true;
        
        //update balance in address
        walletERC721Balance[ERC721Locker[_id].tokenAddress][msg.sender] = walletERC721Balance[ERC721Locker[_id].tokenAddress][msg.sender].sub(1);
        
        //remove this id from this address
        uint256 i; uint256 j;
        for(j=0; j<depositsByWithdrawalAddress[ERC721Locker[_id].withdrawalAddress].length; j++){
            if(depositsByWithdrawalAddress[ERC721Locker[_id].withdrawalAddress][j] == _id){
                for (i = j; i<depositsByWithdrawalAddress[ERC721Locker[_id].withdrawalAddress].length-1; i++){
                    depositsByWithdrawalAddress[ERC721Locker[_id].withdrawalAddress][i] = depositsByWithdrawalAddress[ERC721Locker[_id].withdrawalAddress][i+1];
                }
                depositsByWithdrawalAddress[ERC721Locker[_id].withdrawalAddress].length--;
                break;
            }
        }
        emit LogERC721Withdrawal(msg.sender, ERC721Locker[_id].tokenId);
    }
    

    
    event LogERC1155Withdrawal(address to, uint tokenId, uint tokenAmount);
    
    function withdrawERC1155Tokens(uint256 _id) public {
        require(block.timestamp >= ERC1155Locker[_id].unlockTime, 'Unlock time is still in future');
        require(msg.sender == ERC1155Locker[_id].withdrawalAddress, 'Can withdraw by withdrawal Address only');
        require(!ERC1155Locker[_id].withdrawn, 'ERC1155Token already withdrawn');
        
        
        address _tokenAddress = ERC1155Locker[_id].tokenAddress;
        uint _tokenId = ERC1155Locker[_id].tokenId;
        uint _tokenAmount = ERC1155Locker[_id].tokenAmount;
        ERC1155Token(_tokenAddress).safeTransferFrom(
            this, msg.sender, _tokenId, _tokenAmount, abi.encodePacked(_tokenAddress)
        );
        ERC1155Locker[_id].withdrawn = true;
        
        // //update balance in address
        walletERC1155Balance[ERC1155Locker[_id].tokenAddress][msg.sender] = walletERC1155Balance[ERC1155Locker[_id].tokenAddress][msg.sender].sub(lockedToken[_id].tokenAmount);
        
        //remove this id from this address
        uint256 i; uint256 j;
        for(j=0; j<depositsByWithdrawalAddress[ERC1155Locker[_id].withdrawalAddress].length; j++){
            if(depositsByWithdrawalAddress[ERC1155Locker[_id].withdrawalAddress][j] == _id){
                for (i = j; i<depositsByWithdrawalAddress[ERC1155Locker[_id].withdrawalAddress].length-1; i++){
                    depositsByWithdrawalAddress[ERC1155Locker[_id].withdrawalAddress][i] = depositsByWithdrawalAddress[ERC1155Locker[_id].withdrawalAddress][i+1];
                }
                depositsByWithdrawalAddress[ERC1155Locker[_id].withdrawalAddress].length--;
                break;
            }
        }
        emit LogERC1155Withdrawal(msg.sender, _tokenId, _tokenAmount);
    }
    

     /*get total token balance in contract*/
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
    {
       return Token(_tokenAddress).balanceOf(this);
    }
    
    /*get total token balance by address*/
    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256)
    {
       return walletTokenBalance[_tokenAddress][_walletAddress];
    }
    
    /*get allDepositIds*/
    function getAllDepositIds() view public returns (uint256[] memory)
    {
        return allDepositIds;
    }
    
    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id) view public returns (address, address, uint256, uint256, bool)
    {
        return(lockedToken[_id].tokenAddress,lockedToken[_id].withdrawalAddress,lockedToken[_id].tokenAmount,
        lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }
    
    /*get DepositsByWithdrawalAddress*/
    function getDepositsByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory)
    {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }
    
}

