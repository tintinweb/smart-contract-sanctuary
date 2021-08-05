/**
 *Submitted for verification at Etherscan.io on 2020-05-14
*/

pragma solidity >=0.5.16 <0.6.9;
//INCONTRACTWETRUST
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

contract EthereumeRush {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address payable public fundsWallet;
    uint256 public maximumTarget;
    uint256 public lastBlock;
    uint256 public rewardTimes;
    uint256 public genesisReward;
    uint256 public premined;
    uint256 public nRewarMod;
    uint256 public nWtime;
    uint256 public totalReceived;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        initialSupply = 21919180  * 10 ** uint256(decimals);
        tokenName = "EthereumeRush";
        tokenSymbol = "EER";
        lastBlock = 135;
        nRewarMod = 5200;
        nWtime = 3788923100; 
        genesisReward = (2**14)* (10**uint256(decimals));
        maximumTarget = 100  * 10 ** uint256(decimals);
        fundsWallet = msg.sender;
        premined = 3000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = premined;
        balanceOf[address(this)] = initialSupply;
        totalSupply =  initialSupply + premined;
        name = tokenName;
        symbol = tokenSymbol;
        totalReceived = 0;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }



    function uintToString(uint256 v) internal pure returns(string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a,"-",b));
    }




    function getblockhash() public view returns (uint256) {
            return uint256(blockhash(block.number-1));
    }

    function getspesificblockhash(uint256 _blocknumber) public view returns(uint256, uint256){
        uint256 crew = uint256(blockhash(_blocknumber)) % nRewarMod;
        return (crew, block.number-1);
    }




    function checkRewardStatus() public view returns (uint256, uint256) {
        uint256 crew = uint256(blockhash(block.number-1)) % nRewarMod;
        return (crew, block.number-1);
    }




    struct sdetails {
      uint256 _stocktime;
      uint256 _stockamount;
    }


    address[] totalminers;

    mapping (address => sdetails) nStockDetails;
    struct rewarddetails {
        uint256 _artyr;
        bool _didGetReward;
        bool _didisign;
    }
    mapping (string => rewarddetails) nRewardDetails;

    struct nBlockDetails {
        uint256 _bTime;
        uint256 _tInvest;
    }
    mapping (uint256 => nBlockDetails) bBlockIteration;


  struct activeMiners {
      address bUser;
  }

  mapping(uint256 => activeMiners[]) aMiners;


    function numberofminer() view public returns (uint256) {
        return totalminers.length;
    }


    function nAddrHash() view public returns (uint256) {
        return uint256(msg.sender) % 10000000000;
    }

     function getmaximumAverage() public view returns(uint){
         if(numberofminer() == 0){
             return maximumTarget;
         } else {
             return maximumTarget / numberofminer();
         }
    }


    


   function checkAddrMinerStatus(address _addr) view public returns(bool){
    if(nStockDetails[_addr]._stocktime == 0){
        return false;
    } else {
        return true;
    }
   }

   function checkAddrMinerAmount(address _addr) view public returns(uint256){
    if(nStockDetails[_addr]._stocktime == 0){
        return 0;
    } else {
        return nStockDetails[_addr]._stockamount;
    }
   }





   function getactiveminersnumber() view public returns(uint256) {
        return aMiners[lastBlock].length; //that function for information.
   }
   
   
   function nMixAddrandBlock()  private view returns(string memory) {
         return append(uintToString(nAddrHash()),uintToString(lastBlock));
    }
    
    
   
   function signfordailyreward(uint256 _bnumber) public returns (uint256)  {
       require(checkAddrMinerStatus(msg.sender) == true);
       require((block.number-1) - _bnumber  <= 100);
       require(uint256(blockhash(_bnumber)) % nRewarMod == 1);
        if(bBlockIteration[lastBlock]._bTime + 1800 < now){
           lastBlock += 1;
           bBlockIteration[lastBlock]._bTime = now;
       }
       require(nRewardDetails[nMixAddrandBlock()]._artyr == 0);
       bBlockIteration[lastBlock]._tInvest += nStockDetails[msg.sender]._stockamount;
       nRewardDetails[nMixAddrandBlock()]._artyr = now;
       nRewardDetails[nMixAddrandBlock()]._didGetReward = false;
       nRewardDetails[nMixAddrandBlock()]._didisign = true;
       aMiners[lastBlock].push(activeMiners(msg.sender));
       return 200;
   }

   
   function getDailyReward(uint256 _bnumber) public returns(uint256) {
       require(checkAddrMinerStatus(msg.sender) == true);
       require((block.number-1) - _bnumber  >= 100);
       require(uint256(blockhash(_bnumber)) % nRewarMod == 1);
       require(nRewardDetails[nMixAddrandBlock()]._didGetReward == false);
       require(nRewardDetails[nMixAddrandBlock()]._didisign == true);
       uint256 totalRA = genesisReward / 2 ** (lastBlock/730);
       uint256 usersReward = (totalRA * (nStockDetails[msg.sender]._stockamount * 100) / bBlockIteration[lastBlock]._tInvest) /  100;
       nRewardDetails[nMixAddrandBlock()]._didGetReward = true;
       _transfer(address(this), msg.sender, usersReward);
       return usersReward;
   }

    function becameaminer(uint256 mineamount) public returns (uint256) {
      uint256 realMineAmount = mineamount * 10 ** uint256(decimals);
      require(realMineAmount > getmaximumAverage() / 100); //Minimum maximum targes one percents neccessary.
      require(realMineAmount > 1 * 10 ** uint256(decimals)); //minimum 1 coin require
      require(nStockDetails[msg.sender]._stocktime == 0);
      require(mineamount <= 3000);
      maximumTarget +=  realMineAmount;
      nStockDetails[msg.sender]._stocktime = now;
      nStockDetails[msg.sender]._stockamount = realMineAmount;
      totalminers.push(msg.sender);
      _transfer(msg.sender, address(this), realMineAmount);
      return 200;
   }



   function getyourcoinsbackafterthreemonths() public returns(uint256) {
       require(checkAddrMinerStatus(msg.sender) == true);
       require(nStockDetails[msg.sender]._stocktime + nWtime < now  );
       nStockDetails[msg.sender]._stocktime = 0;
       _transfer(address(this),msg.sender,nStockDetails[msg.sender]._stockamount);
       return nStockDetails[msg.sender]._stockamount;
   }

   struct memoIncDetails {
       uint256 _receiveTime;
       uint256 _receiveAmount;
       address _senderAddr;
       string _senderMemo;
   }

  mapping(address => memoIncDetails[]) textPurchases;
  function sendtokenwithmemo(uint256 _amount, address _to, string memory _memo)  public returns(uint256) {
      textPurchases[_to].push(memoIncDetails(now, _amount, msg.sender, _memo));
      _transfer(msg.sender, _to, _amount);
      return 200;
  }


   function checkmemopurchases(address _addr, uint256 _index) view public returns(uint256,
   uint256,
   string memory,
   address) {

       uint256 rTime = textPurchases[_addr][_index]._receiveTime;
       uint256 rAmount = textPurchases[_addr][_index]._receiveAmount;
       string memory sMemo = textPurchases[_addr][_index]._senderMemo;
       address sAddr = textPurchases[_addr][_index]._senderAddr;
       if(textPurchases[_addr][_index]._receiveTime == 0){
            return (0, 0,"0", _addr);
       }else {
            return (rTime, rAmount,sMemo, sAddr);
       }
   }



   function getmemotextcountforaddr(address _addr) view public returns(uint256) {
       return  textPurchases[_addr].length;
   }
 }