/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

pragma solidity >=0.5.16 <0.6.9;
pragma experimental ABIEncoderV2;
//YOUWILLNEVERWALKALONE
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

contract StarkChain {
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
        initialSupply = 8886000  * 10 ** uint256(decimals);
        tokenName = "Stark Chain";
        tokenSymbol = "STARK";
        lastBlock = 206;
        nRewarMod = 34344;        
        nWtime = 7776000;        
        genesisReward = (10**uint256(decimals)); // Ödül Miktarı
        maximumTarget = 100  * 10 ** uint256(decimals);
        fundsWallet = msg.sender;
        premined = 73005 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = premined;
        balanceOf[address(this)] = initialSupply;
        totalSupply =  initialSupply + premined;
        name = tokenName;
        symbol = tokenSymbol;
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
   

    function getCurrentBlockHash() public view returns (uint256) {
            return uint256(blockhash(block.number-1));
    }

    function getBlockHashAlgoritm(uint256 _blocknumber) public view returns(uint256, uint256){
        uint256 crew = uint256(blockhash(_blocknumber)) % nRewarMod;
        return (crew, block.number-1);
    }

    function checkBlockReward() public view returns (uint256, uint256) {
        uint256 crew = uint256(blockhash(block.number-1)) % nRewarMod;
        return (crew, block.number-1);
    }

    struct stakeInfo {
      uint256 _stocktime;
      uint256 _stockamount;
    }

    address[] totalminers;

    mapping (address => stakeInfo) nStockDetails;

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


    function totalMinerCount() view public returns (uint256) {
        return totalminers.length;
    }


    function addressHashs() view public returns (uint256) {
        return uint256(msg.sender) % 10000000000;
    }    


    function stakerStatus(address _addr) view public returns(bool){

        if(nStockDetails[_addr]._stocktime == 0)
        {
            return false;
        }
        else 
        {
            return true;
        }
    }

    function stakerAmount(address _addr) view public returns(uint256){

        if(nStockDetails[_addr]._stocktime == 0)
        {
            return 0;
        } 
        else 
        {
            return nStockDetails[_addr]._stockamount;
        }
    }

    function stakerTimeStart(address _addr) view public returns(uint256){

        return nStockDetails[_addr]._stocktime;
    }


    function stakerActiveTotal() view public returns(uint256) {
        return aMiners[lastBlock].length; 
    }
   
   
    function generalCheckPoint()  private view returns(string memory) {
       return append(uintToString(addressHashs()),uintToString(lastBlock));
    }  
    
   
    function necessarySignForReward(uint256 _bnumber) public returns (uint256)  { 
       require(stakerStatus(msg.sender) == true);
       require((block.number-1) - _bnumber  <= 200);        
       require(nStockDetails[msg.sender]._stocktime + nWtime > now);   
       require(uint256(blockhash(_bnumber)) % nRewarMod == 1);
       
       if(bBlockIteration[lastBlock]._bTime + 1800 < now)       
       {
           lastBlock += 1;
           bBlockIteration[lastBlock]._bTime = now;
       }
       require(nRewardDetails[generalCheckPoint()]._artyr == 0);

       bBlockIteration[lastBlock]._tInvest += nStockDetails[msg.sender]._stockamount;
       nRewardDetails[generalCheckPoint()]._artyr = now;
       nRewardDetails[generalCheckPoint()]._didGetReward = false;
       nRewardDetails[generalCheckPoint()]._didisign = true;
       aMiners[lastBlock].push(activeMiners(msg.sender));
       return 200;
   }

   
   function rewardGet(uint256 _bnumber) public returns(uint256) { 
       require(stakerStatus(msg.sender) == true);
       require((block.number-1) - _bnumber  > 200);        
       require(uint256(blockhash(_bnumber)) % nRewarMod == 1);
       require(nStockDetails[msg.sender]._stocktime + nWtime > now  ); 
       require(nRewardDetails[generalCheckPoint()]._didGetReward == false);
       require(nRewardDetails[generalCheckPoint()]._didisign == true);
       
       uint256 halving = lastBlock / 365;   
       

       uint256 totalRA = 128 * genesisReward;
       
       if(halving==0)
       {
           totalRA = 128 * genesisReward;
       }
       else if(halving==1)
       {
           totalRA = 256 * genesisReward;
       }
       else if(halving==2)
       {
           totalRA = 512 * genesisReward;
       }
       else if(halving==3)
       {
           totalRA = 1024 * genesisReward;
       }
       else if(halving==4)
       {
           totalRA = 2048 * genesisReward;
       }
       else if(halving==5)
       {
           totalRA = 4096 * genesisReward;
       }
       else if(halving==6)
       {
           totalRA = 8192 * genesisReward;
       }
       else if(halving==7)
       {
           totalRA = 4096 * genesisReward;
       }
       else if(halving==8)
       {
           totalRA = 2048 * genesisReward;
       }
       else if(halving==9)
       {
           totalRA = 1024 * genesisReward;
       }
       else if(halving==10)
       {
           totalRA = 512 * genesisReward;
       }
       else if(halving==11)
       {
           totalRA = 256 * genesisReward;
       }
       else if(halving==12)
       {
           totalRA = 128 * genesisReward;
       }
       else if(halving==13)
       {
           totalRA = 64 * genesisReward;
       }
       else if(halving==14)
       {
           totalRA = 32 * genesisReward;
       }
       else if(halving==15)
       {
           totalRA = 16 * genesisReward;
       }
       else if(halving==16)
       {
           totalRA = 8 * genesisReward;
       }
       else if(halving==17)
       {
           totalRA = 4 * genesisReward;
       }
       else if(halving==18)
       {
           totalRA = 2 * genesisReward;
       }
       else if(halving==19)
       {
           totalRA = 1 * genesisReward;
       }
       else if(halving>19)
       {
           totalRA = 1 * genesisReward;
       }

       uint256 usersReward = (totalRA * (nStockDetails[msg.sender]._stockamount * 100) / bBlockIteration[lastBlock]._tInvest) /  100;
       nRewardDetails[generalCheckPoint()]._didGetReward = true;
       _transfer(address(this), msg.sender, usersReward);
       return usersReward;
   }

   function startMining(uint256 mineamount) public returns (uint256) {

      uint256 realMineAmount = mineamount * 10 ** uint256(decimals);     
      require(realMineAmount >= 10 * 10 ** uint256(decimals)); 
      require(nStockDetails[msg.sender]._stocktime == 0);     
      maximumTarget +=  realMineAmount;
      nStockDetails[msg.sender]._stocktime = now;
      nStockDetails[msg.sender]._stockamount = realMineAmount;
      totalminers.push(msg.sender);
      _transfer(msg.sender, address(this), realMineAmount);
      return 200;
   }

   function tokenPayBack() public returns(uint256) {
       require(stakerStatus(msg.sender) == true);
       require(nStockDetails[msg.sender]._stocktime + nWtime < now  );
       nStockDetails[msg.sender]._stocktime = 0;
       _transfer(address(this),msg.sender,nStockDetails[msg.sender]._stockamount);
       return nStockDetails[msg.sender]._stockamount;
   }

   struct memoInfo {
       uint256 _receiveTime;
       uint256 _receiveAmount;
       address _senderAddr;
       string _senderMemo;
   }

  mapping(address => memoInfo[]) memoGetProcess;

  function sendMemoToken(uint256 _amount, address _to, string memory _memo)  public returns(uint256) {
      memoGetProcess[_to].push(memoInfo(now, _amount, msg.sender, _memo));
      _transfer(msg.sender, _to, _amount);
      return 200;
  }

  function sendMemoOnly(address _to, string memory _memo)  public returns(uint256) {
      memoGetProcess[_to].push(memoInfo(now,0, msg.sender, _memo));
      _transfer(msg.sender, _to, 0);
      return 200;
  }


  function yourMemos(address _addr, uint256 _index) view public returns(uint256,
   uint256,
   string memory,
   address) {

       uint256 rTime = memoGetProcess[_addr][_index]._receiveTime;
       uint256 rAmount = memoGetProcess[_addr][_index]._receiveAmount;
       string memory sMemo = memoGetProcess[_addr][_index]._senderMemo;
       address sAddr = memoGetProcess[_addr][_index]._senderAddr;
       if(memoGetProcess[_addr][_index]._receiveTime == 0){
            return (0, 0,"0", _addr);
       }else {
            return (rTime, rAmount,sMemo, sAddr);
       }
  }


   function yourMemosCount(address _addr) view public returns(uint256) {
       return  memoGetProcess[_addr].length;
   }

   function appendMemos(string memory a, string memory b,string memory c,string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a,"#",b,"#",c,"#",d));
   }

   function addressToString(address _addr) public pure returns(string memory) {
    bytes32 value = bytes32(uint256(_addr));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(51);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
        str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
}

   function getYourMemosOnly(address _addr) view public returns(string[] memory) {
       
       uint total =  memoGetProcess[_addr].length;
       string[] memory messages = new string[](total);
      
       for (uint i=0; i < total; i++) {
             
            messages[i] = appendMemos(uintToString(memoGetProcess[_addr][i]._receiveTime),memoGetProcess[_addr][i]._senderMemo,uintToString(memoGetProcess[_addr][i]._receiveAmount),addressToString(memoGetProcess[_addr][i]._senderAddr));
       }

       return messages;
   }

}