pragma solidity ^0.4.0;

contract Ownable {
  address public owner;
  
  constructor() public {
    owner = msg.sender;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

 function mod(uint256 a, uint256 b) internal pure returns (uint256){
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a % b;
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function transfer(address _to, uint256 _value) public  returns (bool);


   function burnTokens(uint256 _value)
        public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



contract Pre_ICO_1 is Ownable{

       using SafeMath for uint256;

        uint constant public HARD_CAP =   4934 * 10**18;
        uint constant public SOFT_CAP =   700 * 10**18;
        // rate is the number of tokens per ether
        uint constant public rate = 144000;
        bool isSaleStart = false;

        uint public icoStartDate;
        uint public endDate;
        uint public totalWeiCollected;
        ERC20 _tokenContract;

        address public beneficiary = 0x42fe95cbe8c4befd4e60e24aa3e66485185ae863;

        constructor() public {
            //address of token contract
            _tokenContract = ERC20(0x90f8d966ff7a7dac55caf055b93dd24485fe68ea);
        }

        //this function is called whenever some spender send ethers to this contract
        function() public payable {
             buyTokens();
        }

        function buyTokens() public payable {
            require(msg.value>0);

            require(endDate>0);


            uint weiCollectedAfterTransaction = totalWeiCollected.add(msg.value);
            require(weiCollectedAfterTransaction <= HARD_CAP);

            //if softcap is not reached, then extend sale to one month
            if(now>endDate && totalWeiCollected<SOFT_CAP){

                  endDate=endDate.add(2678400);

            }
            require(now<=endDate);

            uint tokenBrought = (msg.value).mul(rate);

            require((_tokenContract.balanceOf(address(this)))>=tokenBrought);

             if(!isSaleStart)
                  isSaleStart = true;
            _tokenContract.transfer(msg.sender,tokenBrought);
            //this line transfer received ethers to beneficiary account
            beneficiary.transfer(msg.value);
        }

        function burnTokens(uint256 _value)  public onlyOwner returns (bool) {
            _tokenContract.burnTokens(_value);
            return true;
        }

        function releaseTokens(uint256 _startDate) public onlyOwner returns(bool){
            require(!isSaleStart);
            icoStartDate= _startDate;
            endDate = _startDate.add(2678400);
            return true;
        }
}