/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

pragma solidity 0.5.17;

contract Ownable {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner to execute");
        _;
    }

    constructor() public{
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}




 library SafeMath256 {

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
   require( b<= a,"Sub Error");
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a,"Add Error");

    return c;
  }

}





contract ERC20 {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);


       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);

       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);


}

contract StandarERC20 is ERC20{
     using SafeMath256 for uint256;
     uint256 public totalSupply;

     mapping (address => uint256) balance;
     mapping (address => mapping (address=>uint256)) allowed;


     function balanceOf(address _walletAddress) public view returns (uint256){
        return balance[_walletAddress];
     }


     function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
        }

     function transfer(address _to, uint256 _value) public returns (bool){
        require(_value <= balance[msg.sender],"In sufficial Balance");
        require(_to != address(0),"Can't transfer To Address 0");

        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);

        return true;

     }

     function approve(address _spender, uint256 _value)
            public returns (bool){
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }

      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from]);
               require(_value <= allowed[_from][msg.sender]);
               require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }
}



contract Casino is StandarERC20, Ownable{

    string public name = "Can You Print Money";
    string public symbol = "USD";
    uint256 public decimals = 18;

    bool public mintingFinished = false;
    uint public totalSupply = 0;

    event MintFinished();

    modifier canMint() {
        if(mintingFinished) revert();
        _;
    }
	/*
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
   function mint(uint _amount) external canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balance[msg.sender] = balance[msg.sender].add(_amount);
        emit Transfer(address(0),msg.sender,_amount);
        return true;
      }

      /**
       * @dev Function to stop minting new tokens.
       * @return True if the operation was successful.
       */
    function finishMinting() external returns(bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
  }
    uint public ContractBalance;

}