/**
 *Submitted for verification at Etherscan.io on 2021-04-23
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



contract Casino is StandarERC20{
    string public name = "Sarfarn Bet Coin";
    string public symbol = "BET";
    uint256 public decimals = 18;
    
    bool public mintingFinished = false;
    uint public totalSupply = 0;
    
    event MintFinished();

    modifier canMint() {
        if(mintingFinished) revert();
        _;
    }


    mapping(address =>uint256) myScore;
    mapping(address =>uint256)  public mintCount;

	uint256 private seed_;

	constructor() public {
		seed_ = uint256(now);
	}

	function rand() internal returns(uint256){

		seed_ = (seed_ * 214013 + 2531011);
		return (seed_ >> 16 ) & 0x7fff;
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


    /*function mintToken(uint256 _amount) external{
      //require(mintCount[msg.sender] < 3,"Maximum mint");
      //require(balance[msg.sender] < 1 ether || balance[msg.sender] > 10 ether);
      //if(_amount > 1 ether) _amount = 1 ether;

      balance[msg.sender] += _amount;
      totalSupply += _amount;
      //mintCount[msg.sender]++;
      //myScore[msg.sender] = rand() % 21 + 1;
      emit Transfer(address(0),msg.sender,_amount);
    }*/

    function PlayGame(address _battleAddress) external returns(bool){
        uint256 oldBalance;
        if(myScore[msg.sender] < myScore[_battleAddress]){
            oldBalance = balance[msg.sender];
            balance[_battleAddress] += balance[msg.sender];
            balance[msg.sender] = 0;
            myScore[_battleAddress] =(myScore[_battleAddress] > 3)?myScore[_battleAddress]-3:0;
            emit Transfer(msg.sender,_battleAddress,oldBalance);
        }
        else
        {
            oldBalance = balance[_battleAddress];
            balance[msg.sender] += balance[_battleAddress];
            balance[_battleAddress] = 0;
            myScore[msg.sender] =(myScore[msg.sender] > 3)?myScore[msg.sender]-3:0;

            emit Transfer(_battleAddress,msg.sender,oldBalance);
        }
    }
}



contract Bet is Ownable{

    uint public ContractBalance;

    event bet(address user, uint bet, bool);
    event fund(address owner, uint funding);
    

    modifier costs(uint cost) {
        require(msg.value >= cost, "The minimum bet is 0.01");
        _;
    }

    function flip() public payable costs(0.01 ether) returns (bool){
        require(address(this).balance >= msg.value, "The balance not enough");
        bool success;
        if(now % 2 == 0) {
            ContractBalance += msg.value;
            success = false;
        }
        else if(now % 2 == 1) {
            ContractBalance -= msg.value;
            msg.sender.transfer(msg.value * 2);
            success = true;
        }
        emit bet(msg.sender, msg.value, success);
        return success;
    }

    function withdrawAll() public onlyOwner returns(uint){
        msg.sender.transfer(address(this).balance);
        assert(address(this).balance == 0);
        return address(this).balance;
    }

    function getBalance() public view returns (address, uint, uint){
        return (address(this), address(this).balance, ContractBalance);
    }

    function fundContract() public payable onlyOwner returns(uint){
        require(msg.value != 0);
        emit fund(msg.sender, msg.value);
        return msg.value;
    }

    function random() public view returns (uint) {
        return now % 2;
    }
}