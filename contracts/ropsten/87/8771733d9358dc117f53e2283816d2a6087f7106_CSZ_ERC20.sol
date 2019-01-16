pragma solidity ^0.4.21;

/*
VERSION DATE: 15/01/2019

CREATED BY: CRYPTO SPORTZ
ENJOY YOUR TEAM AND SPORTS AND EMAIL US IF YOU HAVE ANY QUESTIONS
*/

contract TokenERC20
{
	function balanceOf(address _owner) public view returns (uint256 balance);
	function allowance(address _owner, address _spender) public view returns (uint256 remaining);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Owned 
{
    address private candidate;
	address public owner;

	mapping(address => bool) public admins;
	
    function Owned() public 
	{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public 
	{
		require(msg.sender == owner);
        candidate = newOwner;
    }
	
	function confirmOwner() public 
	{
        require(candidate == msg.sender);
		owner = candidate;
    }
	
    function addAdmin(address addr) public
	{
		require(msg.sender == owner);
        admins[addr] = true;
    }

    function removeAdmin(address addr) public
	{
		require(msg.sender == owner);
        admins[addr] = false;
    }
	
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }
}

contract Functional
{
	function uint2str(uint i) internal pure returns (string)
	{
		if (i == 0) return "0";
		uint j = i;
		uint len;
		while (j != 0){
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len - 1;
		while (i != 0){
			bstr[k--] = byte(48 + i % 10);
			i /= 10;
		}
		return string(bstr);
	}
	
	function strConcat(string _a, string _b, string _c) internal pure returns (string)
	{
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
		string memory abc;
		uint k = 0;
		uint i;
		bytes memory babc;
		if (_ba.length==0)
		{
			abc = new string(_bc.length);
			babc = bytes(abc);
		}
		else
		{
			abc = new string(_ba.length + _bb.length+ _bc.length);
			babc = bytes(abc);
			for (i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
			for (i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
		}
        for (i = 0; i < _bc.length; i++) babc[k++] = _bc[i];
		return string(babc);
	}
	
	function timenow() public view returns(uint32) { return uint32(block.timestamp); }
}

contract CSZ_ERC20 is Owned, Functional
{
	enum Winner
	{
		STAKING,
		MAKER,
		BETTOR,
		CANCEL
	}
	
	struct Params
	{
		address maker;
		uint32 date;
		uint16 rate;					// the probability of winning the maker = (1-99%)
	}
	
	struct Game
	{
		address tokenAddr;
		uint limitMaker;
		uint params;
        mapping(address => int) stake;	// real bets: maker`s>0, bettor`s<0
		uint sumBettorBets;
		uint32 winner;
    }
	
	struct Market
	{
        bytes32 marketHash;
        uint64 gameId;
        uint32 dateStop;
		uint16 rate;
        address maddr;		// maker address
		address taddr;		// token address
		uint mamount;		// maker amount
    }
	
	struct Decision
	{
		bytes32 decisionHash;
		uint64 gameId;
		uint32 winner;
		address aaddr;
	}
	
	uint256 private constant FEECONTRACT = 2;
	mapping(address => uint256) public feeValue;
	
	mapping(address => mapping (address => uint256)) private balances; // tokenAddr->userAddress->balance

	mapping(uint => Game) private games;
	
	mapping(address => bool) public allowTokens;

	uint[] private markets;

	event LogChangeBalance(address indexed account, address indexed tokenAddr, uint oldAmount, uint newAmount);
	event LogMaker(uint gameId, uint date, uint rate, address indexed maker, address indexed tokenAddr, uint amount, bytes32 marketHash);
	event LogBettor(uint gameId, address indexed bettor, address indexed tokenAddr, uint amount, address indexed signer);	
	event LogFinalizeGame(uint gameId, uint32 winner);
	event LogAffiliate(address indexed receiver, address indexed tokenAddr, uint amount);
	event WithdrawFee(address indexed tokenAddr, address indexed user, uint256 count);

	function CSZ_ERC20() public {}

	function allowToken(address[] addrs) onlyAdmin public
	{
		for(uint i = 0; i < addrs.length; i++) 
		{
			allowTokens[addrs[i]] = true;
		}
    }

    function forbidToken(address[] addrs) onlyAdmin public
	{
		for(uint i = 0; i < addrs.length; i++) 
		{
			delete allowTokens[addrs[i]];
		}
    }

	function deposite(address tokenAddr, uint count) public
	{
		require(count > 0);
		require(allowTokens[tokenAddr]);

		TokenERC20 tkn = TokenERC20(tokenAddr);

		uint oldTknAmount = tkn.balanceOf(address(this));
		
		require( tkn.allowance(msg.sender, address(this)) >= count );
		require( tkn.transferFrom(msg.sender, address(this), count) );
		require( tkn.balanceOf(address(this)) == oldTknAmount + count );
				
		uint oldAmount = balances[tokenAddr][msg.sender];
		balances[tokenAddr][msg.sender] = balances[tokenAddr][msg.sender] + count;

		emit LogChangeBalance(msg.sender, tokenAddr, oldAmount, balances[tokenAddr][msg.sender]);
	}
	
	function withdraw(address tokenAddr, uint count) public
	{
		require(count > 0);

		TokenERC20 tkn = TokenERC20(tokenAddr);

		uint oldTknAmount = tkn.balanceOf(address(this));
		
		require( balances[tokenAddr][msg.sender] >= count );
		require( tkn.balanceOf(address(this)) >= count );
		require( tkn.transfer(msg.sender, count) );
		require( tkn.balanceOf(address(this)) == oldTknAmount - count );
		
		uint oldAmount = balances[tokenAddr][msg.sender];
		balances[tokenAddr][msg.sender] = balances[tokenAddr][msg.sender] - count;
		
		emit LogChangeBalance(msg.sender, tokenAddr, oldAmount, balances[tokenAddr][msg.sender]);
	}
	
	function getBalance(address tokenAddr, address addr) public view returns(uint balance)
	{
        balance = balances[tokenAddr][addr];
    }
	
	function getGameInfo(uint gameId) public view returns(
		address maker, 
		uint limitMaker,
		uint32 date, 
		uint32 rate, 
		uint makerStake, 
		uint sumBettorBets, 
		address tokenAddr,
		bool finalized, 
		uint32 winner
	){
        Game storage g = games[gameId];
		Params memory params = unPackParams(g.params);
		maker = params.maker;
		date = params.date;
		rate = params.rate;
		limitMaker = g.limitMaker;
		makerStake = uint(g.stake[maker]);
		sumBettorBets = g.sumBettorBets;
		tokenAddr = g.tokenAddr;
		finalized = g.winner==uint32(Winner.STAKING)?false:true;
		winner = g.winner;
    }

    function getGameStake(uint gameId, address addr) public view returns(uint stake, uint prize, bool maker)
	{
		Game storage g = games[gameId];
		int value = g.stake[addr];
		stake = value>0 ? uint(value) : uint(-value);
		maker = value>0;
		prize = 0;
		Params memory params = unPackParams(g.params);
		if (g.winner!=uint32(Winner.STAKING))
		{
			if (addr == params.maker && g.winner == uint32(Winner.MAKER))  prize =  uint( g.stake[addr]) * 100 / params.rate;
			if (addr != params.maker && g.winner == uint32(Winner.BETTOR)) prize =  uint(-g.stake[addr]) * 100 / (100-params.rate);
			if (addr == params.maker && g.winner == uint32(Winner.CANCEL)) prize =  uint( g.stake[addr]);
			if (addr != params.maker && g.winner == uint32(Winner.CANCEL)) prize =  uint(-g.stake[addr]);
		}
    }

	function getListMarkets(address addr, uint count) public view returns(string res)
	{
		res="";
		uint i;
		uint32 findCount=0;
		Game storage g = games[0];
		
		if (addr!=address(0))
		for (i = markets.length-1; i>=0; i--)
		{
			if(i>markets.length) break;
			g = games[ markets[i] ];
			if (g.stake[addr] != 0) res = strConcat( res, ",", uint2str(markets[i]) );
			findCount++;
			if (count!=0 && findCount>=count) break;
		}
	
		if (addr==address(0))
		for (i = markets.length-1; i>=0; i--)
		{
			if(i>markets.length) break;
			g = games[ markets[i] ];
			if (g.sumBettorBets != 0) res = strConcat( res, ",", uint2str(markets[i]) );
			findCount++;
			if (count!=0 && findCount>=count) break;
		}
	}

	function packParams(address addr, uint16 rate, uint32 date) private pure returns(uint pack)
	{
		pack = ( uint256(date) << 22*8 ) + ( uint256(rate) << 20*8 ) + uint256(addr);
	}

	function unPackParams(uint pack) private pure returns(Params memory params)
	{
		params.date = uint32((pack >> (8*22)) & 0xffffffff);
		params.rate = uint16((pack >> (8*20)) & 0xffff);
        params.maker = address(pack & 0x00ffffffffffffffffffffffffffffffffffffffff);
	}

	function unPackMarket(uint[3] memory market) private pure returns(Market memory m)
	{
        m.marketHash = keccak256( market );

		uint packed = market[0];
		m.gameId   = uint64((packed >> (8*26)) & 0xffffffffffff);
		m.dateStop = uint32((packed >> (8*22)) & 0xffffffff);
		m.rate     = uint16((packed >> (8*20)) & 0xffff);
        m.maddr    = address(packed & 0x00ffffffffffffffffffffffffffffffffffffffff);

		m.mamount = market[1];
		
		packed = market[2];
		m.taddr = address(packed & 0x00ffffffffffffffffffffffffffffffffffffffff);
    }

	// market[0] : [   id  ][  date ][  rate ][  maddr ]
	//             [6 bytes][4 bytes][2 bytes][20 bytes]  = 32 bytes
	// market[1] : [ mamount ] = 32 bytes
	// market[2] : [    0   ][  taddr ]
	//             [12 bytes][20 bytes]   = 32 bytes
	function deal(uint[3] market, uint256 bamount, bytes32 r, bytes32 s, uint8 v) public
	{
		Market memory m = unPackMarket(market);

		require(m.gameId>0 && m.gameId<2**48);
		require(m.dateStop>block.timestamp);
		require(m.rate>0 && m.rate<100);
		require(m.maddr != address(0));
		require(m.maddr != msg.sender);
		require(m.taddr != address(0));
		require(m.mamount > 0 && m.mamount < 2**128);
		require(bamount > 0 && bamount < 2**128);

		Game storage g = games[m.gameId];
        require(g.winner==uint32(Winner.STAKING));

		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		address signer = ecrecover(keccak256(prefix,m.marketHash), v, r, s);
		require(signer==m.maddr);

		if (g.sumBettorBets==0)
		{
			emit LogMaker(m.gameId, m.dateStop, m.rate, m.maddr, m.taddr, m.mamount, m.marketHash );	
			g.params = packParams(m.maddr,m.rate,m.dateStop);			
			g.limitMaker = m.mamount;
			g.tokenAddr = m.taddr;
			markets.push(m.gameId);
		}

		Params memory params = unPackParams(g.params);
		
		require(params.date == m.dateStop);
		require(params.maker == m.maddr);
		require(params.rate == m.rate);
		require(g.limitMaker == m.mamount);
		require(g.tokenAddr == m.taddr);
		
		emit LogBettor(m.gameId, msg.sender, m.taddr, bamount, signer);	
		
		uint mamount = bamount * params.rate / (100-params.rate);
		
		require( balances[m.taddr][m.maddr] >= mamount );
	
		require( balances[m.taddr][msg.sender] >= bamount );
	
		require( (g.limitMaker-uint(g.stake[params.maker])) >= mamount );

		g.stake[msg.sender] -= int(bamount);
		g.stake[m.maddr] += int(mamount);

		balances[m.taddr][m.maddr] -= mamount;
		balances[m.taddr][msg.sender] -= bamount;
		
		g.sumBettorBets += bamount;
	}

	function unPackDecision(uint packed) private pure returns(Decision memory d)
	{
        d.decisionHash = keccak256( packed );
	
		d.gameId   = uint64((packed >> (8*24)) & 0xffffffffffff);
		d.winner   = uint32((packed >> (8*20)) & 0xffffffff);
        d.aaddr    = address(packed & 0x00ffffffffffffffffffffffffffffffffffffffff);
    }
	
	// decision : 
	// [   0   ][   id  ][ winner][  aaddr ]
	// [2 bytes][6 bytes][4 bytes][20 bytes]  = 32 bytes
    function payout(uint256 decision, bytes32 r, bytes32 s, uint8 v) public
	{
		Decision memory d = unPackDecision(decision);
		
        Game storage g = games[d.gameId];

        if (g.winner==uint32(Winner.STAKING)) 
		{
			require(d.winner==uint32(Winner.MAKER) || d.winner==uint32(Winner.BETTOR) || d.winner==uint32(Winner.CANCEL));

			bytes memory prefix = "\x19Ethereum Signed Message:\n32";
			address signer = ecrecover(keccak256(prefix,d.decisionHash), v, r, s);
            require(admins[signer]);

            g.winner = d.winner;
            emit LogFinalizeGame(d.gameId, d.winner);
        }

		require(g.winner!=uint32(Winner.STAKING));

        uint sendValue = 0;
		Params memory params = unPackParams(g.params);

		if (msg.sender == params.maker && g.winner == uint32(Winner.MAKER))  sendValue = uint( g.stake[msg.sender]) * 100 / params.rate;
		if (msg.sender != params.maker && g.winner == uint32(Winner.BETTOR)) sendValue = uint(-g.stake[msg.sender]) * 100 / (100-params.rate);

		if (msg.sender == params.maker && g.winner == uint32(Winner.CANCEL)) sendValue = uint( g.stake[msg.sender]);
		if (msg.sender != params.maker && g.winner == uint32(Winner.CANCEL)) sendValue = uint(-g.stake[msg.sender]);

        require(sendValue > 0);
        g.stake[msg.sender] = 0;

		uint256 curFee = sendValue * FEECONTRACT / 100;
		sendValue = sendValue - curFee;
		
		if (d.aaddr != address(0) && d.aaddr != msg.sender)
		{
			uint aValue = curFee/2;
			curFee = curFee - aValue;
			balances[g.tokenAddr][d.aaddr] = balances[g.tokenAddr][d.aaddr] + aValue;
			emit LogAffiliate(d.aaddr, g.tokenAddr, aValue);
		}
		
		feeValue[g.tokenAddr] = feeValue[g.tokenAddr] + curFee;

		uint oldAmount = balances[g.tokenAddr][msg.sender];
		balances[g.tokenAddr][msg.sender] = balances[g.tokenAddr][msg.sender] + sendValue;
		emit LogChangeBalance(msg.sender, g.tokenAddr, oldAmount, balances[g.tokenAddr][msg.sender]);
    }

	function cancel(uint64 gameId) public 
	{
		Game storage g = games[gameId];
        require(g.winner==uint32(Winner.STAKING) || g.winner==uint32(Winner.CANCEL));
		
		require( g.stake[msg.sender] != 0);
		
		Params memory params = unPackParams(g.params);
		require( timenow() > params.date + 60 days );
		
		if ( g.winner==uint32(Winner.STAKING) )
		{
			g.winner = uint32(Winner.CANCEL);
			emit LogFinalizeGame(gameId, g.winner);
		}
		
		require(g.winner==uint32(Winner.CANCEL));

        uint sendValue = 0;

		if (msg.sender == params.maker) sendValue = uint( g.stake[msg.sender]);
		if (msg.sender != params.maker) sendValue = uint(-g.stake[msg.sender]);

        require(sendValue > 0);
        g.stake[msg.sender] = 0;

		uint256 curFee = sendValue * FEECONTRACT / 100;
		sendValue = sendValue - curFee;
		feeValue[g.tokenAddr] = feeValue[g.tokenAddr] + curFee;

		uint oldAmount = balances[g.tokenAddr][msg.sender];
		balances[g.tokenAddr][msg.sender] = balances[g.tokenAddr][msg.sender] + sendValue;
		emit LogChangeBalance(msg.sender, g.tokenAddr, oldAmount, balances[g.tokenAddr][msg.sender]);
	}
	
	function () onlyOwner payable public { revert(); }
	
	function withdrawFee(address tokenAddr) onlyOwner public
	{
		uint256 tmpFeeValue = feeValue[tokenAddr];
		require( tmpFeeValue > 0 );
		feeValue[tokenAddr] = 0;
		TokenERC20 tkn = TokenERC20(tokenAddr);
		require( tkn.transfer(msg.sender, tmpFeeValue) );
		
		emit WithdrawFee(tokenAddr, msg.sender, tmpFeeValue);
	}
	
}