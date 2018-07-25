pragma solidity ^0.4.23;

interface TokenInterface {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract StateHolder {
    address public owner;
    uint256 public tokenFee;
    TokenInterface token;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function() public payable {}
    
    /** 
      * @dev set transaction fee (HNT token) by owner
      * @param _tokenFee for transaction
      */
    function setFee(uint256 _tokenFee) public onlyOwner {
        tokenFee = _tokenFee;
    }
    
    /**
      * @dev get HNT Token transaction fee 
      */
    function getFee() external view returns(uint256){
        return tokenFee;
    }

    /** 
      * @dev withdraw ether from contract to owner
      */
    function withdrawEther() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    /**
      * @dev withdraw token by owner
      * @param _contractAddress contract address
      */
    function withdrawToken(address _contractAddress) public onlyOwner {
         uint256 currentToken = TokenInterface(_contractAddress).balanceOf(this);
         require(currentToken > 0);
         TokenInterface(_contractAddress).transfer(owner, currentToken);
      }
}