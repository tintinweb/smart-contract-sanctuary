/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.4.24;

library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); 
		uint256 c = a / b;

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}
}

contract ERC20{
	using SafeMath for uint256;

	mapping (address => uint256) public balances;

	uint256 public _totalSupply;

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address owner) public view returns (uint256) {
		return balances[owner];
	}
}

contract B2GBToken is ERC20 {

	string public constant name = "B2GB";
	string public constant symbol = "B2GB";
	uint8 public constant decimals = 18;
	uint256 public constant _airdropAmount = 1000;

	uint256 public constant INITIAL_SUPPLY = 20000000000 * (10 ** uint256(decimals));

	mapping(address => bool) initialized;

	constructor() public {
		initialized[msg.sender] = true;
		_totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}

	// airdrop
	function AirdropCheck() internal returns (bool success){
		 if (!initialized[msg.sender]) {
            initialized[msg.sender] = true;
            balances[msg.sender] = _airdropAmount;
            _totalSupply += _airdropAmount;
        }
        return true;
	}
}

contract Bet2Loss is B2GBToken{
		uint constant MIN_JACKPOT_BET = 0.1 ether;
		uint constant MIN_BET = 1;
		uint constant MAX_BET = 100000;
		uint constant MAX_MODULO = 100;
		uint constant BET_EXPIRATION_BLOCKS = 250;
		address constant DUMMY_ADDRESS = 0x7517401236713DB1520294f650f2e9ABa4cf34bD;
		address public owner;
		address private nextOwner;
		uint public maxProfit;
		address public secretSigner;
		uint128 public jackpotSize;
		uint128 public lockedInBets;

		struct Bet {
				uint betnumber;
				uint8 modulo;
				uint40 placeBlockNumber;
				uint40 mask;
				address gambler;
		}

		mapping (uint => Bet) bets;

		event FailedPayment(address indexed beneficiary, uint amount);
		event Payment(address indexed beneficiary, uint amount);
		event Commit(uint commit);

		event GetFlag(
			string b64email,
			string back
		);

		constructor () public {
				owner = msg.sender;
				secretSigner = DUMMY_ADDRESS;
		}

		modifier onlyOwner {
				require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
				_;
		}

		function setSecretSigner(address newSecretSigner) external onlyOwner {
				secretSigner = newSecretSigner;
		}

		function placeBet(uint betMask, uint modulo, uint betnumber, uint commitLastBlock, uint commit, bytes32 r, bytes32 s, uint8 v) external payable {

				// airdrop
				AirdropCheck();

				Bet storage bet = bets[commit];
				require (bet.gambler == address(0), "Bet should be in a 'clean' state.");
				require (balances[msg.sender] >= betnumber, "no more balances");
				require (modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
				require (betMask >= 0 && betMask < modulo, "Mask should be within range.");
				require (betnumber > 0 && betnumber < 1000, "BetNumber should be within range.");
				

				require (block.number <= commitLastBlock, "Commit has expired.");
				bytes32 signatureHash = keccak256(abi.encodePacked(commitLastBlock, commit));
				require (secretSigner == ecrecover(signatureHash, v, r, s), "ECDSA signature is not valid.");

				uint possibleWinAmount;

				possibleWinAmount = getDiceWinAmount(betnumber, modulo);
				lockedInBets += uint128(possibleWinAmount);

				// require (lockedInBets <= balances[owner], "Cannot afford to lose this bet.");


				balances[msg.sender] = balances[msg.sender].sub(betnumber);
				emit Commit(commit);

				bet.betnumber = betnumber;
				bet.modulo = uint8(modulo);
				bet.placeBlockNumber = uint40(block.number);
				bet.mask = uint40(betMask);
				bet.gambler = msg.sender;
		}

		function settleBet(uint reveal) external {
				AirdropCheck();

				uint commit = uint(keccak256(abi.encodePacked(reveal)));

				Bet storage bet = bets[commit];
				uint placeBlockNumber = bet.placeBlockNumber;

				require (block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
				require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

				settleBetCommon(bet, reveal);
		}


		function settleBetCommon(Bet storage bet, uint reveal) private {
				uint betnumber = bet.betnumber;
				uint mask = bet.mask;
				uint modulo = bet.modulo;
				uint placeBlockNumber = bet.placeBlockNumber;
				address gambler = bet.gambler;

				require (betnumber != 0, "Bet should be in an 'active' state");

				bytes32 entropy = keccak256(abi.encodePacked(reveal, placeBlockNumber));
				uint dice = uint(entropy) % modulo;

				uint diceWinAmount;
				diceWinAmount = getDiceWinAmount(betnumber, modulo);

				uint diceWin = 0;

				if (dice == mask){
					diceWin = diceWinAmount;
				}

				lockedInBets -= uint128(diceWinAmount);

				sendFunds(gambler, diceWin == 0 ? 1 wei : diceWin , diceWin);
		}

		function getDiceWinAmount(uint amount, uint modulo) private pure returns (uint winAmount) {
			winAmount = amount * modulo;
		}

		function sendFunds(address beneficiary, uint amount, uint successLogAmount) private {
			balances[beneficiary] = balances[beneficiary].sub(amount);
			emit Payment(beneficiary, successLogAmount);
		}
		//flag
		function PayForFlag(string b64email) public payable returns (bool success){
		
			require (balances[msg.sender] > 100000000);
			emit GetFlag(b64email, "Get flag!");
		}
}