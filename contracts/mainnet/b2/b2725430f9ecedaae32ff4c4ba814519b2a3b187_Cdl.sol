pragma solidity ^ 0.4.19;
/*
---------------------------------------------------
Let’s play. If you win, we’ll give you the answer.
---------------------------------------------------
       /&#175;&#175;\
   /&#175;&#175;&#175; \\\\_
  ///&&&   \\\
/&&//&&&// ///__
\&&&&///&&// // \
 \//&&//&&&&   //
  &#175;&#175;&#175;&#175;&#175;&#175;&#175;&#175;&#175;&#175;&#175;&#175;&#175;

 _______
|      |\
|      |_\
| ~~~~~~~ |
| ~~~~~~~ |
| ~~~~~~~ |
|_________|


#,         ,#
 ##       ##
  ###, ,###
   &#39;#####&#39;
/##### #####/
#   #   #   #
 ###     ###

 ---------------------------------------------------
 https://www.casheth.org/
 ---------------------------------------------------
 
 */
contract Cdl {
    using SafeXHD for uint;
    uint public constant configTimeInit = 24 hours;
    uint public constant configTimeInc = 30 seconds;
    uint public constant configTimeMax = 24 hours;
    uint public constant configRunTime = 24 hours;
    uint public constant configPerShares = 75;
    uint public constant configPerFund = 10;
    uint public constant configRoundKey = 75000000000000;
    uint public constant configRoundKeyAdd = 156230000;
    uint public constant configMaxKeys = 10000000;
    uint public runTime = 0;
    uint public allEth = 0;
    uint public allEthShares = 0;
    uint public allTime = 0;
    uint public allKeys = 0;
    uint public roundEth = 0;
    uint public roundEthShares = 0;
    uint public roundTime = 0;
    uint public roundKeys = 0;
    uint public round = 0;
    uint public roundPot = 0;
    uint public roundPrice = 0;
    uint private roundToSharesPrice=0;
    address public roundLeader;
    mapping(address => uint) public accountRounds;
    mapping(address => uint) public accountShares;
    mapping(address => uint) public accountSharesOut;
    mapping(address => uint) public accountKeys;
    address[] roundAddress;
    address public owner;
    uint public ownerEth = 0;
    function doStart() public payable returns(uint) {
        require(round == 0);
        require(runTime <= 0);
        require(
            msg.sender == 0xbEBA30E7F05581fd7330A58743b0331BD7dd5508 ||
            msg.sender == 0x479F9dFAdaF30Fba069d8a9f017D881C648B5ac0 ||
            msg.sender == 0x7B034094a0D1F1545c5558F422E71EdA6f47313D ||
            msg.sender == 0x9DDA48c596fc52642ace5A0ff470425e4d550095 ||
            msg.sender == 0xE05ac79525bdB0Ec238Bd2982Fb63Ca2d7f778a0 ||
            msg.sender == 0x57854E9293789854dF8fCfDd3AD845bf15e35BBc ||
            msg.sender == 0x968F54Fd6edDEEcEBfE2B0CA45BfEe82D2629BfE);

        runTime = now.add(configRunTime);
        roundTime = runTime.add(configTimeInit);
        owner = msg.sender; 
        roundPrice = configRoundKey;
        round = round.add(1);
        roundLeader = owner;
        roundAddress = [owner];
        return runTime;
    }

    function buyKey() public payable newRoundIfNeeded returns(uint) {
      
            require(msg.value > 0);
            uint _msgValue = msg.value;
            uint _amountToShares = _msgValue.div(100).mul(configPerShares); 
            uint _amountToFund = _msgValue.div(100).mul(configPerFund); 
            uint _amountToPot = _msgValue.sub(_amountToShares).sub(_amountToFund);
             uint _keys = _msgValue.div(roundPrice);
            require(configMaxKeys >= _keys); 
			ownerEth=ownerEth.add(_amountToFund);
            fundoShares(_amountToShares); 
            roundEth = roundEth.add(_msgValue);
            roundEthShares = roundEthShares.add(_amountToShares);
            roundKeys = roundKeys.add(_keys);
            roundPot = roundPot.add(_amountToPot);
            allEth = allEth.add(_msgValue);
            allEthShares = allEthShares.add(_amountToShares);
            allKeys = allKeys.add(_keys);
            funComputeRoundPrice();
            funComputeRoundTime(_keys); 
            roundLeader = msg.sender;

            if (accountKeys[msg.sender] <= 0 || accountRounds[msg.sender] != round) roundAddress.push(msg.sender);
            if (accountRounds[msg.sender] == round) {
                accountKeys[msg.sender] = accountKeys[msg.sender].add(_keys);
            } else {
                accountRounds[msg.sender] = round;
                accountKeys[msg.sender] = _keys;
            }
             
            return _keys;
           
        }

    function withdrawl() public payable newRoundIfNeeded returns(uint) {
        require(accountShares[msg.sender] > 0);
        uint _withdraw = accountShares[msg.sender].sub(accountSharesOut[msg.sender]);
        require(_withdraw > 0);
        accountSharesOut[msg.sender] = accountSharesOut[msg.sender].add(_withdraw);
        msg.sender.transfer(_withdraw);
        return _withdraw;
    }

    function withdrawlOwner() public payable returns(uint) {
		require(
            msg.sender == 0xbEBA30E7F05581fd7330A58743b0331BD7dd5508 ||
            msg.sender == 0x479F9dFAdaF30Fba069d8a9f017D881C648B5ac0 ||
            msg.sender == 0x7B034094a0D1F1545c5558F422E71EdA6f47313D ||
            msg.sender == 0x9DDA48c596fc52642ace5A0ff470425e4d550095 ||
            msg.sender == 0xE05ac79525bdB0Ec238Bd2982Fb63Ca2d7f778a0 ||
            msg.sender == 0x57854E9293789854dF8fCfDd3AD845bf15e35BBc ||
            msg.sender == 0x968F54Fd6edDEEcEBfE2B0CA45BfEe82D2629BfE
        );
        require(ownerEth> 0);
        msg.sender.transfer(ownerEth);
		ownerEth=0;
        return ownerEth;
    }

    modifier newRoundIfNeeded {
        require(runTime > 0);
        require(now > runTime);
        require(round > 0);
      
        if (now > roundTime) {
            uint _nextPot = 0;
            uint _leaderEarnings = roundPot.sub(_nextPot);
            accountShares[roundLeader] = accountShares[roundLeader].add(_leaderEarnings);
            round++;
            roundPot = _nextPot;
            roundLeader = owner;
            roundTime = now.add(configTimeInit);
            roundEth = roundPot;
            roundEthShares = 0;
            roundKeys = 0;
            funComputeRoundPrice(); 
            allEth = allEth.add(roundEth);
            allEthShares = allEthShares.add(roundEthShares);
            roundAddress = [owner];
        }
       
        _;
    }


    function funComputeRoundTime(uint keys) private {
        uint _now = now;
        if (_now >= roundTime)
            roundTime = (configTimeInc.mul(keys)).add(_now);
        else
            roundTime = (configTimeInc.mul(keys)).add(roundTime);

        if (roundTime >= (configTimeMax).add(_now))
            roundTime = (configTimeMax).add(_now);
        allTime = allTime.add(configTimeInc.mul(keys));
    }

    function funComputeRoundPrice() private {
            if (roundKeys > 0) roundPrice = configRoundKey.add(roundKeys.mul(configRoundKeyAdd));
            if (roundKeys <= 0 || roundPrice <= configRoundKey) roundPrice = configRoundKey;
        }

    function fundoShares(uint _amountToShares) private {
        roundToSharesPrice=0;
        require(_amountToShares > roundKeys);
         roundToSharesPrice = _amountToShares.div(roundKeys);
        for (uint i = 0; i < roundAddress.length; i++) {
            address _address = roundAddress[i];
            if (accountRounds[_address] == round && _address != owner) {
                 accountShares[_address] = accountShares[_address].add(roundToSharesPrice.mul(accountKeys[_address]));
            }
        }
    }

}


library SafeXHD {
   
    function div(uint a, uint b) internal pure returns(uint) {
            if (b == 0) {
                return 0;
            }
            uint c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
            return c;
        }
     
    function mul(uint a, uint b) internal pure returns(uint) {
            if (a == 0) {
                return 0;
            }
            uint c = a * b;
            assert(c / a == b);
            return c;
        }
      
    function sub(uint a, uint b) internal pure returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

}