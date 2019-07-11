/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity 0.5.8;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SwapContract
 * @dev A contract to depsoit Tokens and get your address registered for bep2 receival
 */
contract BawSwapContract{
    
    ERC20 public token;
    address public owner;
    uint public bb;
    
    /**
    * @param _token An address for ERC20 token which would be swaped be bep2
    */
    constructor(ERC20 _token) public {
        token = _token;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    
    event OwnerChanged(address oldOwner, address newOwner);
    
    /**
    * @dev only to be called by the owner of Swap contract
    * @param _newOwner An address to replace the old owner with.
    */
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(msg.sender, owner);
    }
    
    event Swaped(uint tokenAmount, string BNB_Address);
    
    /**
    * @param tokenAmount Amount of tokens to swap with bep2
    * @param BNB_Address address of Binance Chain to which to receive the bep2 tokens
    */
    function swap(uint tokenAmount, string memory BNB_Address) public returns(bool) {
        
        bool success = token.transferFrom(msg.sender, owner, tokenAmount);
        
        if(!success) {
            revert("Transfer of tokens to Swap contract failed.");
        }
        
        emit Swaped(tokenAmount, BNB_Address);
        
        return true;
        
    }
    
}