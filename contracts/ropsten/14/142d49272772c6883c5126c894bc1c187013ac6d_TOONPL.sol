/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^0.4.24;


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function checkRate(uint unlockIndex) public constant returns (uint rate_);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Blacklisted(address indexed target);
    
	event DeleteFromBlacklist(address indexed target);
	event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint value);
	event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint value);
	event RejectedPaymentToLockedAddr(address indexed from, address indexed to, uint value, uint lackdatetime, uint now_);
	event RejectedPaymentFromLockedAddr(address indexed from, address indexed to, uint value, uint lackdatetime, uint now_);
	event RejectedPaymentMaximunFromLockedAddr(address indexed from, address indexed to, uint value, uint maximum, uint rate);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract TOONPL is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public TGE;

    address addr_1	= 0x57c6Be1710A8FE4D978192C274285E6c6b969134; // 팀, 고문 (10%):	50000000
    address addr_2	= 0x327867571295FA2057dDFe8941D9ef805aB4969C; // 생태계 파트너 (5%):	25000000
	address addr_3	= 0xd3fA962D8C355b5E1b62751570D3EFEC8392f644; // 생태계 예비금 (15%):	75000000
	address addr_4	= 0x8097075b91B677A825b3F1068c6397a9FA947a0c; // 생태계 바운티 (15%):	75000000
	address addr_5	= 0x1313D460402C8f8B8E460B811E3630Eb47de8FeB; // 커뮤니티 인센티브(10%):	50000000
	address addr_6	= 0x0dc378b67F8B657c141E2f1a91B5094C00396E76; // Seed Round (8%):	40000000
	address addr_7	= 0x9835799C833784bE414b09FCeD59904213E7B4C9; // 프라이빗 세일 (7%):	35000000
	address addr_8	= 0x693ee01e197c1B3c7bE6a13317fC8BE07d2d7055; // IEO 세일 (30%):	150000000

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => int8) public blacklist;
    UnlockDateModel[] public unlockdate_T1;
    UnlockDateModel[] public unlockdate_T2;

    struct UnlockDateModel {
		uint256 datetime;
		uint rate;
	}
	
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "TPL";
        name = "TOONPL";
        decimals = 18;
        _totalSupply = 5000000000000000000000000000;
        
        balances[addr_1] = 500000000000000000000000000; // 팀, 고문 (10%)
        emit Transfer(address(0), addr_1, balances[addr_1]); 
        balances[addr_2] = 250000000000000000000000000; // 생태계 파트너 (5%)
        emit Transfer(address(0), addr_2, balances[addr_2]); 
        balances[addr_3] = 750000000000000000000000000; // 생태계 예비금 (15%)
        emit Transfer(address(0), addr_3, balances[addr_3]); 
        balances[addr_4] = 750000000000000000000000000; // 생태계 바운티 (15%)
        emit Transfer(address(0), addr_4, balances[addr_4]); 
        balances[addr_5] = 500000000000000000000000000; // 커뮤니티 인센티브(10%)
        emit Transfer(address(0), addr_5, balances[addr_5]); 
        balances[addr_6] = 400000000000000000000000000; // Seed (8%)
        emit Transfer(address(0), addr_6, balances[addr_6]); 
        balances[addr_7] = 350000000000000000000000000; // 프라이빗 세일 (7%)
        emit Transfer(address(0), addr_7, balances[addr_7]); 
        balances[addr_8] = 1500000000000000000000000000; // IEO 세일 (30%)
        emit Transfer(address(0), addr_8, balances[addr_8]); 
        
        TGE = now;
        
        unlockdate_T1.push(UnlockDateModel({datetime : TGE + 210 days, rate : 200}));
        unlockdate_T1.push(UnlockDateModel({datetime : TGE + 240 days, rate : 200}));
        unlockdate_T1.push(UnlockDateModel({datetime : TGE + 270 days, rate : 200}));
        unlockdate_T1.push(UnlockDateModel({datetime : TGE + 300 days, rate : 200}));
        unlockdate_T1.push(UnlockDateModel({datetime : TGE + 330 days, rate : 200}));
        
        unlockdate_T2.push(UnlockDateModel({datetime : TGE + 150 days, rate : 125}));
        unlockdate_T2.push(UnlockDateModel({datetime : TGE + 180 days, rate : 125}));
        unlockdate_T2.push(UnlockDateModel({datetime : TGE + 210 days, rate : 125}));
        unlockdate_T2.push(UnlockDateModel({datetime : TGE + 240 days, rate : 125}));
        unlockdate_T2.push(UnlockDateModel({datetime : TGE + 270 days, rate : 125}));
        unlockdate_T2.push(UnlockDateModel({datetime : TGE + 300 days, rate : 125}));
        unlockdate_T2.push(UnlockDateModel({datetime : TGE + 330 days, rate : 125}));
        unlockdate_T2.push(UnlockDateModel({datetime : TGE + 360 days, rate : 125}));
        
    }
    
    function now_() public constant returns (uint){
        return now;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function checkRate(uint unlockIndex) public constant returns (uint rate_ ){
        uint rate = 0;
        if (unlockIndex == 1){
            for (uint i = 0; i<unlockdate_T1.length; i++) {
                if (unlockdate_T1[i].datetime < now) {
                    rate = rate + unlockdate_T1[i].rate; 
                }
            }
        } else if (unlockIndex == 2){
            for (uint s = 0; s<unlockdate_T2.length; s++) {
                if (unlockdate_T2[s].datetime < now) {
                    rate = rate + unlockdate_T2[s].rate; 
                }
            }
        }
        return rate;
    }
    
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
  
    function transfer(address to, uint tokens) public returns (bool success) {
        if (to == addr_1 || to == addr_2 || to == addr_6){
            emit RejectedPaymentToLockedAddr(msg.sender, to, tokens, unlockdate_T1[4].datetime, now);
			require(false);
        }
        
        if (msg.sender == addr_1){ //  팀, 고문 (10%)
            if (unlockdate_T1[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(msg.sender, to, tokens, unlockdate_T1[0].datetime, now);
			    require(false);
            } else {
                uint rate1 = checkRate(1);
                uint maximum1 = 500000000000000000000000000 - (500000000000000000000000000 * 0.001) * rate1;
                if (maximum1 > (balances[msg.sender] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(msg.sender, to, tokens, maximum1, rate1);
			        require(false);
                }
            }
        } else if (msg.sender == addr_2){ // 생태계 파트너 (5%)
            if (unlockdate_T1[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(msg.sender, to, tokens, unlockdate_T1[0].datetime, now);
			    require(false);
            } else {
                uint rate2 = checkRate(1);
                uint maximum2 = 250000000000000000000000000 - (250000000000000000000000000 * 0.001) * rate2;
                if (maximum2 > (balances[msg.sender] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(msg.sender, to, tokens, maximum2, rate2);
			        require(false);
                }
            }
        } else if (msg.sender == addr_7){ // 프라이빗 세일 (7%)
            if (unlockdate_T1[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(msg.sender, to, tokens, unlockdate_T1[0].datetime, now);
			    require(false);
            } else {
                uint rate3 = checkRate(1);
                uint maximum3 = 350000000000000000000000000 - (350000000000000000000000000 * 0.001) * rate3;
                if (maximum3 > (balances[msg.sender] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(msg.sender, to, tokens, maximum3, rate3);
			        require(false);
                }
            }
        } else if (msg.sender == addr_6) { // Seed Round (8%)
            if (unlockdate_T2[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(msg.sender, to, tokens, unlockdate_T2[0].datetime, now);
			    require(false);
            } else {
                uint rate8 = checkRate(2);
                uint maximum8 = 400000000000000000000000000 - (400000000000000000000000000 * 0.001) * rate8;
                if (maximum8 > (balances[msg.sender] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(msg.sender, to, tokens, maximum8, rate8);
			        require(false);
                }
            }
        }
        
        if (blacklist[msg.sender] > 0) { // Accounts in the blacklist can not be withdrawn
			emit RejectedPaymentFromBlacklistedAddr(msg.sender, to, tokens);
			require(false);
		} else if (blacklist[to] > 0) { // Accounts in the blacklist can not be withdrawn
			emit RejectedPaymentToBlacklistedAddr(msg.sender, to, tokens);
			require(false);
		} else {
			balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(msg.sender, to, tokens);
		}
		return true;
		
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (to == addr_1 || to == addr_2 || to == addr_6){
            emit RejectedPaymentToLockedAddr(from, to, tokens, unlockdate_T1[4].datetime, now);
			require(false);
        }
        
        if (from == addr_1){ //  팀, 고문 (10%)
            if (unlockdate_T1[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(from, to, tokens, unlockdate_T1[0].datetime, now);
			    require(false);
            } else {
                uint rate1 = checkRate(1);
                uint maximum1 = 500000000000000000000000000 - (500000000000000000000000000 * 0.001) * rate1;
                if (maximum1 > (balances[from] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(from, to, tokens, maximum1, rate1);
			        require(false);
                }
            }
        } else if (from == addr_2){ // 생태계 파트너 (5%)
            if (unlockdate_T1[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(from, to, tokens, unlockdate_T1[0].datetime, now);
			    require(false);
            } else {
                uint rate2 = checkRate(1);
                uint maximum2 = 250000000000000000000000000 - (250000000000000000000000000 * 0.001) * rate2;
                if (maximum2 > (balances[from] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(from, to, tokens, maximum2, rate2);
			        require(false);
                }
            }
        } else if (from == addr_7){ // 프라이빗 세일 (7%)
            if (unlockdate_T1[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(from, to, tokens, unlockdate_T1[0].datetime, now);
			    require(false);
            } else {
                uint rate3 = checkRate(1);
                uint maximum3 = 350000000000000000000000000 - (350000000000000000000000000 * 0.001) * rate3;
                if (maximum3 > (balances[from] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(from, to, tokens, maximum3, rate3);
			        require(false);
                }
            }
        } else if (from == addr_6) { // Seed Round (8%)
            if (unlockdate_T2[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(from, to, tokens, unlockdate_T2[0].datetime, now);
			    require(false);
            } else {
                uint rate8 = checkRate(2);
                uint maximum8 = 400000000000000000000000000 - (400000000000000000000000000 * 0.001) * rate8;
                if (maximum8 > (balances[from] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(from, to, tokens, maximum8, rate8);
			        require(false);
                }
            }
        }
        
        if (blacklist[from] > 0) { // Accounts in the blacklist can not be withdrawn
			emit RejectedPaymentFromBlacklistedAddr(from, to, tokens);
			require(false);
		} else if (blacklist[to] > 0) { // Accounts in the blacklist can not be withdrawn
			emit RejectedPaymentToBlacklistedAddr(from, to, tokens);
			require(false);
		} else {
		    balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(from, to, tokens);
		}
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
	
	// ------------------------------------------------------------------------
    // Owner can add blacklist the wallet address.
    // ------------------------------------------------------------------------
	function blacklisting(address _addr) public onlyOwner{
		blacklist[_addr] = 1;
		emit Blacklisted(_addr);
	}
	
	
	// ------------------------------------------------------------------------
    // Owner can delete from blacklist the wallet address.
    // ------------------------------------------------------------------------
	function deleteFromBlacklist(address _addr) public onlyOwner{
		blacklist[_addr] = -1;
		emit DeleteFromBlacklist(_addr);
	}
	
}