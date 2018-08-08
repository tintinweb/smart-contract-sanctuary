pragma solidity 0.4.21;



    // Tipbot, Crypto For Everyone



    // Contract Owner - Tipbot - 0x72BA45c9e729f13CD2F6AA4B410f83bE1410E982



    // Official Website - http://www.Tipbot.io

    // Official Twitter - http://www.twitter.com/officialtipbot

    // Official Reddit - http://www.reddit.com/r/officialtipbot

    // Official Telegram - http://www.t.me/officialtipbot/



    // Contract Developed By - Tipbot LTD




library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }



    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        // assert(b > 0); 

        uint256 c = a / b;

        // assert(a == b * c + a % b); 

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



contract Ownable {

    address public owner;





    function Ownable() public {

        owner = msg.sender;

    }





    modifier onlyOwner() {

        require(msg.sender == owner);

        _;

    }





    function transferOwnership(address newOwner) public onlyOwner {

        require(newOwner != address(0));

        owner = newOwner;

    }



}



contract ERC20Basic {

    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}



contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



contract tipbotreg {

    uint256 public stakeCommence;

    uint256 public stakeMinAge;

    uint256 public stakeMaxAge;

    function mint() public returns (bool);

    function coinAge() public payable returns (uint256);

    function annualInterest() public view returns (uint256);

    event Mint(address indexed _address, uint _reward);

}







 // Initial Configuration

 

 

contract tipbot is ERC20,tipbotreg,Ownable {

        using SafeMath for uint256;



        string public name = "tipbot";

        string public symbol = "TIP";

        

        uint public decimals = 18;



        

        uint public stakeCommence; //Proof Of Stake Start Timestamp

        

        uint public stakeMinAge = 3 days; // Minimum Age For Coin Age: 3 days

        

        uint public stakeMaxAge = 90 days; // Maximimum age for coin age: 90 days

        

        uint public maxMintPoS = 10**17; // Proof Of Stake default interest equates to 10% annually

        

        uint public chainStartTime; // The timestamp in which the chain starts

        

        uint public chainStartBlock; //The block number in which the chain starts



        uint public totalSupply;

        

        uint public maxTIPSupply;

        

        uint public initialTIPsupply;



        struct transferInStruct{

        

        uint256 amount;

        

        uint64 time;

    }



        mapping(address => uint256) balances;

        

        mapping(address => mapping (address => uint256)) allowed;

        

        mapping(address => transferInStruct[]) transferIns;



    event Burn(address indexed burner, uint256 value);



   

   

   modifier onlyPayloadSize(uint size) {

        require(msg.data.length >= size + 4);

        _;

    }



    modifier canTIPMint() {

        require(totalSupply < maxTIPSupply);

        _;

    }



    function tipbot() public {

    

    // 104 Billion Token Initial Supply

        initialTIPsupply = 104000000000000000000000000000; 

        

    // 375 Billion Maximum Token Supply.

        maxTIPSupply = 375000000000000000000000000000; 

        

        chainStartTime = block.timestamp;

        chainStartBlock = block.number;



        balances[msg.sender] = initialTIPsupply;

        totalSupply = initialTIPsupply;

    }

    

 // Transfer Function

 

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {

        if(msg.sender == _to) return mint();

        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];

        uint64 _now = uint64(block.timestamp);

        transferIns[msg.sender].push(transferInStruct(uint256(balances[msg.sender]),_now));

        transferIns[_to].push(transferInStruct(uint256(_value),_now));

        return true;

    }

    



 // Balance Function

 

    function balanceOf(address _owner) public view returns (uint256 balance) {

        return balances[_owner];

    }

    



 // Transfer Function

 

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {

        require(_to != address(0));



        uint256 _allowance = allowed[_from][msg.sender];



        balances[_from] = balances[_from].sub(_value);

        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);

        emit Transfer(_from, _to, _value);

        if(transferIns[_from].length > 0) delete transferIns[_from];

        uint64 _now = uint64(block.timestamp);

        transferIns[_from].push(transferInStruct(uint256(balances[_from]),_now));

        transferIns[_to].push(transferInStruct(uint256(_value),_now));

        return true;

    }

    

// PoS must be manually triggered by the contract creator using a UNIX timestamp. It is advisable to set the timestamp 15 minutes ahead of time to prevent failure



    function ownerSetStakeCommence(uint timestamp) public onlyOwner {

        require((stakeCommence <= 0) && (timestamp >= chainStartTime));

        stakeCommence = timestamp;

    }

    



//approve function



    function approve(address _spender, uint256 _value) public returns (bool) {

        require((_value == 0) || (allowed[msg.sender][_spender] == 0));



        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }

    

    



    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {

        return allowed[_owner][_spender];

    }





 // Mint Function

 

 

    function mint() public canTIPMint returns (bool) {

        if(balances[msg.sender] <= 0) return false;

        if(transferIns[msg.sender].length <= 0) return false;



        uint reward = getPoSReward(msg.sender);

        if(reward <= 0) return false;



        totalSupply = totalSupply.add(reward);

        balances[msg.sender] = balances[msg.sender].add(reward);

        delete transferIns[msg.sender];

        transferIns[msg.sender].push(transferInStruct(uint256(balances[msg.sender]),uint64(block.timestamp)));



        emit Mint(msg.sender, reward);

        return true;

    }



    function getBlockNumber() public view returns (uint blockNumber) {

        blockNumber = block.number.sub(chainStartBlock);

    }

    

// Coin Age Function



    function coinAge() public payable returns (uint myCoinAge) {

        myCoinAge = getCoinAge(msg.sender,block.timestamp);

    }



// Annual Interest  Function

    function annualInterest() public view returns(uint interest) {

        uint _now = block.timestamp;

        interest = maxMintPoS;

        if((_now.sub(stakeCommence)).div(365 days) == 0) {

            interest = (770 * maxMintPoS).div(100);

        } else if((_now.sub(stakeCommence)).div(365 days) == 1){

            interest = (435 * maxMintPoS).div(100);

        }

    }





// Stake Reward Function



    function getPoSReward(address _address) internal view returns (uint) {

        require( (block.timestamp >= stakeCommence) && (stakeCommence > 0) );



        uint _now = block.timestamp;

        uint _coinAge = getCoinAge(_address, _now);

        if(_coinAge <= 0) return 0;



        uint interest = maxMintPoS;

       

        if((_now.sub(stakeCommence)).div(365 days) == 0) {

            interest = (770 * maxMintPoS).div(100);

        } else if((_now.sub(stakeCommence)).div(365 days) == 1){

            // 2nd year effective annual interest rate is 50%

            interest = (435 * maxMintPoS).div(100);

        }



        return (_coinAge * interest).div(365 * (10**decimals));

    }



    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {

        if(transferIns[_address].length <= 0) return 0;



        for (uint i = 0; i < transferIns[_address].length; i++){

            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;



            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));

            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;



            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));

        }

    }



 // Batch Transfer Function

 

    function batchTransfer(address[] _recipients, uint[] _values) public onlyOwner returns (bool) {

        require( _recipients.length > 0 && _recipients.length == _values.length);



        uint total = 0;

        for(uint i = 0; i < _values.length; i++){

            total = total.add(_values[i]);

        }

        require(total <= balances[msg.sender]);



        uint64 _now = uint64(block.timestamp);

        for(uint j = 0; j < _recipients.length; j++){

            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);

            transferIns[_recipients[j]].push(transferInStruct(uint256(_values[j]),_now));

            emit Transfer(msg.sender, _recipients[j], _values[j]);

        }



        balances[msg.sender] = balances[msg.sender].sub(total);

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];

        if(balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint256(balances[msg.sender]),_now));



        return true;

    }

    

// Batch Token Function



        function TokenBurn(uint _value) public onlyOwner {

        require(_value > 0);



        balances[msg.sender] = balances[msg.sender].sub(_value);

        delete transferIns[msg.sender];

        transferIns[msg.sender].push(transferInStruct(uint256(balances[msg.sender]),uint64(block.timestamp)));



        totalSupply = totalSupply.sub(_value);

        initialTIPsupply = initialTIPsupply.sub(_value);

        maxTIPSupply = maxTIPSupply.sub(_value*10);



        emit Burn(msg.sender, _value);

    }

   

}