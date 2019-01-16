pragma solidity ^0.5.0;
/* Oh wow, it&#39;s finally happening /*
╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║           $$$$$$$\            $$\      $$\ $$\   $$\        $$$$$$\  $$$$$$$\        $$$$$$$$\                       ║
║           $$  __$$\           $$ | $\  $$ |$$ |  $$ |      $$ ___$$\ $$  __$$\       $$  _____|                      ║
║           $$ |  $$ | $$$$$$\  $$ |$$$\ $$ |$$ |  $$ |      \_/   $$ |$$ |  $$ |      $$ |      $$\   $$\             ║
║           $$$$$$$  |$$  __$$\ $$ $$ $$\$$ |$$$$$$$$ |        $$$$$ / $$ |  $$ |      $$$$$\    \$$\ $$  |            ║
║           $$  ____/ $$ /  $$ |$$$$  _$$$$ |$$  __$$ |        \___$$\ $$ |  $$ |      $$  __|    \$$$$  /             ║
║           $$ |      $$ |  $$ |$$$  / \$$$ |$$ |  $$ |      $$\   $$ |$$ |  $$ |      $$ |       $$  $$<              ║
║           $$ |      \$$$$$$  |$$  /   \$$ |$$ |  $$ |      \$$$$$$  |$$$$$$$  |      $$$$$$$$\ $$  /\$$\             ║
║           \__|       \______/ \__/     \__|\__|  \__|       \______/ \_______/       \________|\__/  \__|            ║
║                                                                                                                      ║
╠══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║           _____                  __          __  __          __        _      _    _                 _               ║
║          |  __ \                / _|        / _| \ \        / /       | |    | |  | |               | |              ║
║          | |__) | __ ___   ___ | |_    ___ | |_   \ \  /\  / /__  __ _| | __ | |__| | __ _ _ __   __| |___           ║
║          |  ___/ &#39;__/ _ \ / _ \|  _|  / _ \|  _|   \ \/  \/ / _ \/ _` | |/ / |  __  |/ _` | &#39;_ \ / _` / __|          ║
║          | |   | | | (_) | (_) | |   | (_) | |      \  /\  /  __/ (_| |   <  | |  | | (_| | | | | (_| \__ \          ║
║          |_|   |_|  \___/ \___/|_|    \___/|_|       \/  \/ \___|\__,_|_|\_\ |_|  |_|\__,_|_| |_|\__,_|___/          ║
║                       ____  _____        ________   _________ ______ _   _ _____  ______ _____                       ║
║                      |___ \|  __ \   _  |  ____\ \ / /__   __|  ____| \ | |  __ \|  ____|  __ \                      ║
║                        __) | |  | | (_) | |__   \ V /   | |  | |__  |  \| | |  | | |__  | |  | |                     ║
║                       |__ <| |  | |     |  __|   > <    | |  |  __| | . ` | |  | |  __| | |  | |                     ║
║                       ___) | |__| |  _  | |____ / . \   | |  | |____| |\  | |__| | |____| |__| |                     ║
║                      |____/|_____/  (_) |______/_/ \_\  |_|  |______|_| \_|_____/|______|_____/                      ║
║                                             ╔══════════════════════════╗                                             ║
╚═════════════════════════════════════════════╣ Created by ARitz Cracker ╠═════════════════════════════════════════════╝
											  ╚══════════════════════════╝

In a world, where  people wanted more 3rd party dApp integration with P3D, a small "Jack of all trades" developer,
ARitz Cracker set out to create an addon-token for P3D that would add the functionality required for 3rd party dApp
integration. However, while creating this, he had another calling... Replacing web3js and Metamask a grand feat, for
sure. Unfortunately, this left the extension token aside. One man took advantage of this functionality-vacuum and
created his own extension, but it was forged by greed... and would force its users to pay additional fees and taxes to
the creator and anyone he saw fit. ARitz Cracker saw this as a sign... "People need community focused dApp extensions
now!" And so, he set out to have it completed, audited, and ready for the community as soon as possible... In order to
prevent the greedy ones from taking power away from the community.

Thus, P3X was born.

Also, this is my first contract on main-net please be gentle :S
*/

// Interfaces for easy copypasta

interface ERC20interface {
	function transfer(address to, uint value) external returns(bool success);
	function approve(address spender, uint tokens) external returns(bool success);
	function transferFrom(address from, address to, uint tokens) external returns(bool success);

	function allowance(address tokenOwner, address spender) external view returns(uint remaining);
	function balanceOf(address tokenOwner) external view returns(uint balance);
}

interface ERC223interface {
	function transfer(address to, uint value) external returns(bool ok);
	function transfer(address to, uint value, bytes calldata data) external returns(bool ok);
	function transfer(address to, uint value, bytes calldata data, string calldata customFallback) external returns(bool ok);

	function balanceOf(address who) external view returns(uint);
}

// If your contract wants to accept P3X, implement this function
interface ERC223Handler {
	function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

// External gauntlet interfaces can be useful for something like voting systems or contests
interface ExternalGauntletInterface {
	function gauntletRequirement(address wearer, uint256 oldAmount, uint256 newAmount) external returns(bool);
	function gauntletRemovable(address wearer) external view returns(bool);
}

// This is P3D itself (not a cimplete interface)
interface Hourglass {
	function decimals() external view returns(uint8);
	function stakingRequirement() external view returns(uint256);
	function balanceOf(address tokenOwner) external view returns(uint);
	function dividendsOf(address tokenOwner) external view returns(uint);
	function calculateTokensReceived(uint256 _ethereumToSpend) external view returns(uint256);
	function calculateEthereumReceived(uint256 _tokensToSell) external view returns(uint256);
	function myTokens() external view returns(uint256);
	function myDividends(bool _includeReferralBonus) external view returns(uint256);
	function totalSupply() external view returns(uint256);

	function transfer(address to, uint value) external returns(bool);
	function buy(address referrer) external payable returns(uint256);
	function sell(uint256 amount) external;
	function withdraw() external;
}

// This a name database used in Fomo3D (Also not a complete interface)
interface TeamJustPlayerBook {
	function pIDxName_(bytes32 name) external view returns(uint256);
	function pIDxAddr_(address addr) external view returns(uint256);
	function getPlayerAddr(uint256 pID) external view returns(address);
}

// Here&#39;s an interface in case you want to integration your dApp with this.
// Descriptions of each function are down below in the soure code.
// NOTE: It&#39;s not _entirely_ compatible with the P3D interface. myTokens() has been renamed to myBalance().
/*
interface HourglassX {
	function buy(address referrerAddress) payable external returns(uint256 tokensReceieved);
	function buy(string calldata referrerName) payable external returns(uint256 tokensReceieved);
	function reinvest() external returns(uint256 tokensReceieved);
	function reinvestPartial(uint256 ethToReinvest) external returns(uint256 tokensReceieved);
	function reinvestPartial(uint256 ethToReinvest, bool withdrawAfter) external returns(uint256 tokensReceieved);
	function sell(uint256 amount, bool withdrawAfter) external returns(uint256 ethReceieved);
	function sell(uint256 amount) external returns(uint256 ethReceieved); // Alias of sell(amount, false)
	function withdraw() external;
	function exit() external;
	function acquireGauntlet(uint256 amount, uint8 gType, uint256 end) external;
	function acquireExternalGauntlet(uint256 amount, address extGauntlet) external;
	function setReferrer(address referrer) external;
	function setReferrer(string calldata referrerName) external;

	function myBalance() external view returns(uint256 balance);
	function dividendsOf(address accountHolder, bool includeReferralBonus) external view returns(uint256 divs);
	function dividendsOf(address accountHolder) external view returns(uint256 divs); // Alias of dividendsOf(accountHolder, true)
	function myDividends(bool includeReferralBonus) external view returns(uint256 divs);
	function myDividends() external view returns(uint256 divs); // Alias of myDividends(true);

	function usableBalanceOf(address accountHolder) external view returns(uint256 balance);
	function myUsableBalance() external view returns(uint256 balance);
	function refBonusOf(address customerAddress) external view returns(uint256);
	function myRefBonus() external view returns(uint256);
	function gauntletTypeOf(address accountHolder) external view returns(uint256 stakeAmount, uint256 gType, uint256 end);
	function myGauntletType() external view returns(uint256 stakeAmount, uint256 gType, uint256 end);
	function stakingRequirement() external view returns(uint256);
	function savedReferral(address accountHolder) external view returns(address);

	// ERC 20/223
	function balanceOf(address tokenOwner) external view returns(uint balance);
	function transfer(address to, uint value) external returns(bool ok);
	function transfer(address to, uint value, bytes data) external returns(bool ok);
	function transfer(address to, uint value, bytes data, string customFallback) external returns(bool ok);
	function allowance(address tokenOwner, address spender) external view returns(uint remaining);
	function approve(address spender, uint tokens) external returns(bool success);
	function transferFrom(address from, address to, uint tokens) external returns(bool success);

	// Events (cannot be in interfaces used here as a reference)
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event Transfer(address indexed from, address indexed to, uint value);
	event Transfer(address indexed from, address indexed to, uint value, bytes data);
	event onTokenPurchase(
		address indexed accountHolder,
		uint256 ethereumSpent,
		uint256 tokensCreated,
		uint256 tokensGiven,
		address indexed referrer,
		uint8 bitFlags // 1 = invalidMasternode, 2 = usedHourglassMasternode, 4 = reinvestment
	);
	event onTokenSell(
		address indexed accountHolder,
		uint256 tokensDestroyed,
		uint256 ethereumEarned
	);
	event onWithdraw(
		address indexed accountHolder,
		uint256 earningsWithdrawn,
		uint256 refBonusWithdrawn,
		bool reinvestment
	);
	event onDonatedDividends(
		address indexed donator,
		uint256 ethereumDonated
	);
	event onGauntletAcquired(
		address indexed strongHands,
		uint256 stakeAmount,
		uint8 gauntletType,
		uint256 end
	);
	event onExternalGauntletAcquired(
		address indexed strongHands,
		uint256 stakeAmount,
		address indexed extGauntlet
	);
	// Gauntlet events will be emitted with stakeAmount == 0 when the gauntlets expire.
}
*/

// This contract is intended to only be used by HourglassX. Think of this as HourglassX&#39;s second account (or child slave with its own account)

contract HourglassXReferralHandler {
	using SafeMath for uint256;
	using SafeMath for uint;
	address internal parent;
	Hourglass internal hourglass;

	constructor(Hourglass h) public {
		hourglass = h;
		parent = msg.sender;
	}

	// Don&#39;t expose this account to literally everyone
	modifier onlyParent {
		require(msg.sender == parent, "Can only be executed by parent process");
		_;
	}

	// Contract&#39;s total ETH balance including divs
	function totalBalance() public view returns(uint256) {
		return address(this).balance + hourglass.myDividends(true);
	}

	// Buy P3D from given ether
	function buyTokens(address referrer) public payable onlyParent {
		hourglass.buy.value(msg.value)(referrer);
	}

	// Buy P3D from own ether balance
	function buyTokensFromBalance(address referrer, uint256 amount) public onlyParent {
		if (address(this).balance < amount) {
			hourglass.withdraw();
		}
		hourglass.buy.value(amount)(referrer);
	}

	// Sell a specified amount of P3D for ether
	function sellTokens(uint256 amount) public onlyParent {
		if (amount > 0) {
			hourglass.sell(amount);
		}
	}

	// Withdraw outstanding divs to internal balance
	function withdrawDivs() public onlyParent {
		hourglass.withdraw();
	}

	// Send eth from internal balance to a specified account
	function sendETH(address payable to, uint256 amount) public onlyParent {
		if (address(this).balance < amount) {
			hourglass.withdraw();
		}
		to.transfer(amount);
	}

	// Only allow ETH from our master or from the hourglass.
	function() payable external {
		require(msg.sender == address(hourglass) || msg.sender == parent, "No, I don&#39;t accept donations");
	}

	// Reject possible accidental sendin of higher-tech shitcoins.
	function tokenFallback(address from, uint value, bytes memory data) public pure {
		revert("I don&#39;t want your shitcoins!");
	}

	// Allow anyone else to take forcefully sent low-tech shitcoins. (I sure as hell don&#39;t want them)
	function takeShitcoin(address shitCoin) public {
		require(shitCoin != address(hourglass), "P3D isn&#39;t a shitcoin");
		ERC20interface s = ERC20interface(shitCoin);
		s.transfer(msg.sender, s.balanceOf(address(this)));
	}
}

contract HourglassX {
	using SafeMath for uint256;
	using SafeMath for uint;
	using SafeMath for int256;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	modifier playerBookEnabled {
		require(address(playerBook) != NULL_ADDRESS, "named referrals not enabled");
		_;
	}

	// Make the thing
	constructor(address h, address p) public {
		// Set up ERC20 values
		name = "PoWH3D Extended";
		symbol = "P3X";
		decimals = 18;
		totalSupply = 0;

		// Add external contracts
		hourglass = Hourglass(h);
		playerBook = TeamJustPlayerBook(p);

		// Set referral requirement to be the same as P3D by default.
		referralRequirement = hourglass.stakingRequirement();

		// Yes I could deploy 2 contracts myself, but I&#39;m lazy. :^)
		refHandler = new HourglassXReferralHandler(hourglass);

		// Internal stuffs
		ignoreTokenFallbackEnable = false;
		owner = msg.sender;
	}
	// HourglassX-specific data
	address owner;
	address newOwner;

	uint256 referralRequirement;
	uint256 internal profitPerShare = 0;
	uint256 public lastTotalBalance = 0;
	uint256 constant internal ROUNDING_MAGNITUDE = 2**64;
	address constant internal NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

	// I would get this from hourglass, but these values are inaccessable to the public.
	uint8 constant internal HOURGLASS_FEE = 10;
	uint8 constant internal HOURGLASS_BONUS = 3;

	// External contracts
	Hourglass internal hourglass;
	HourglassXReferralHandler internal refHandler;
	TeamJustPlayerBook internal playerBook;

	// P3X Specific data
	mapping(address => int256) internal payouts;
	mapping(address => uint256) internal bonuses;
	mapping(address => address) public savedReferral;

	// Futureproofing stuffs
	mapping(address => mapping (address => bool)) internal ignoreTokenFallbackList;
	bool internal ignoreTokenFallbackEnable;

	// Gauntlets
	mapping(address => uint256) internal gauntletBalance;
	mapping(address => uint256) internal gauntletEnd;
	mapping(address => uint8) internal gauntletType; // 1 = Time, 2 = P3D Supply, 3 = External

	// Normal token data
	mapping(address => uint256) internal balances;
	mapping(address => mapping (address => uint256)) internal allowances;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;

	// --Events
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event Transfer(address indexed from, address indexed to, uint value);
	event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
	// Q: Why do you have 2 transfer events?
	// A: Because keccak256("Transfer(address,address,uint256)") != keccak256("Transfer(address,address,uint256,bytes)")
	//    and etherscan listens for the former.


	event onTokenPurchase(
		address indexed accountHolder,
		uint256 ethereumSpent,
		uint256 tokensCreated,
		// If P3D is given to the contract, that amount in P3X will be given to the next buyer since we have no idea who gave us the P3D.
		uint256 tokensGiven,
		address indexed referrer,
		uint8 indexed bitFlags // 1 = invalidMasternode, 2 = usedHourglassMasternode, 4 = reinvestment
	);
	event onTokenSell(
		address indexed accountHolder,
		uint256 tokensDestroyed,
		uint256 ethereumEarned
	);
	event onWithdraw(
		address indexed accountHolder,
		uint256 earningsWithdrawn,
		uint256 refBonusWithdrawn,
		bool indexed reinvestment
	);
	event onDonatedDividends(
		address indexed donator,
		uint256 ethereumDonated
	);
	event onGauntletAcquired(
		address indexed strongHands,
		uint256 stakeAmount,
		uint8 indexed gauntletType,
		uint256 end
	);
	event onExternalGauntletAcquired(
		address indexed strongHands,
		uint256 stakeAmount,
		address indexed extGauntlet
	);
	// --Events--

	// --Owner only functions
	function setNewOwner(address o) public onlyOwner {
		newOwner = o;
	}

	function acceptNewOwner() public {
		require(msg.sender == newOwner);
		owner = msg.sender;
	}

	// P3D allows re-branding, makes sense if P3X allows it too.
	function rebrand(string memory n, string memory s) public onlyOwner {
		name = n;
		symbol = s;
	}

	// P3X selling point: _lower staking requirement than P3D!!_
	function setReferralRequirement(uint256 r) public onlyOwner {
		referralRequirement = r;
	}

	// Enables the function defined below.
	function allowIgnoreTokenFallback() public onlyOwner {
		ignoreTokenFallbackEnable = true;
	}
	// --Owner only functions--

	// --Public write functions

	// Ethereum _might_ implement something where every address, including ones controlled by humans, is a smart contract.
	// Obviously transfering P3X to other people with no fee is one of its selling points.
	// A somewhat future-proofing fix is for the sender to specify that their recipiant is human if such a change ever takes place.
	// However, due to the popularity of ERC223, this might not be necessary.
	function ignoreTokenFallback(address to, bool ignore) public {
		require(ignoreTokenFallbackEnable, "This function is disabled");
		ignoreTokenFallbackList[msg.sender][to] = ignore;
	}

	// Transfer tokens to the specified address, call the specified function, and pass the specified data
	function transfer(address payable to, uint value, bytes memory data, string memory func) public returns(bool) {
		actualTransfer(msg.sender, to, value, data, func, true);
		return true;
	}

	// Transfer tokens to the specified address, call tokenFallback, and pass the specified data
	function transfer(address payable to, uint value, bytes memory data) public returns(bool) {
		actualTransfer(msg.sender, to, value, data, "", true);
		return true;
	}

	// Transfer tokens to the specified address, call tokenFallback if applicable
	function transfer(address payable to, uint value) public returns(bool) {
		actualTransfer(msg.sender, to, value, "", "", !ignoreTokenFallbackList[msg.sender][to]);
		return true;
	}

	// Allow someone else to spend your tokens
	function approve(address spender, uint value) public returns(bool) {
		require(updateUsableBalanceOf(msg.sender) >= value, "Insufficient balance to approve");
		allowances[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	// Have that someone else spend your tokens
	function transferFrom(address payable from, address payable to, uint value) public returns(bool success) {
		uint256 allowance = allowances[from][msg.sender];
		require(allowance > 0, "Not approved");
		require(allowance >= value, "Over spending limit");
		allowances[from][msg.sender] = allowance.sub(value);
		actualTransfer(from, to, value, "", "", false);
		return true;
	}

	// The fallback function
	function() payable external{
		// Only accept free ETH from the hourglass and from our child slave.
		if (msg.sender != address(hourglass) && msg.sender != address(refHandler)) {
			// Now, sending ETH increases the balance _before_ the transaction has been fully processed.
			// We don&#39;t want to distribute the entire purchase order as dividends.
			if (msg.value > 0) {
				lastTotalBalance += msg.value;
				distributeDividends(0, NULL_ADDRESS);
				lastTotalBalance -= msg.value;
			}
			createTokens(msg.sender, msg.value, NULL_ADDRESS, false);
		}
	}

	// Worried about having weak hands? Put on an optional gauntlet.
	// Prevents you from selling or transfering a specified amount of tokens
	function acquireGauntlet(uint256 amount, uint8 gType, uint256 end) public{
		require(amount <= balances[msg.sender], "Insufficient balance");

		// We need to apply the data first in order to prevent re-entry attacks.
		// ExternalGauntletInterface.gauntletRequirement _is_ a function which can change the state, after all.
		uint256 oldGauntletType = gauntletType[msg.sender];
		uint256 oldGauntletBalance = gauntletBalance[msg.sender];
		uint256 oldGauntletEnd = gauntletEnd[msg.sender];

		gauntletType[msg.sender] = gType;
		gauntletEnd[msg.sender] = end;
		gauntletBalance[msg.sender] = amount;

		if (oldGauntletType == 0) {
			if (gType == 1) {
				require(end >= (block.timestamp + 97200), "Gauntlet time must be >= 4 weeks"); //97200 seconds = 3 weeks and 6 days.
				emit onGauntletAcquired(msg.sender, amount, gType, end);
			} else if (gType == 2) {
				uint256 P3DSupply = hourglass.totalSupply();
				require(end >= (P3DSupply + (P3DSupply / 5)), "Gauntlet must make a profit"); // P3D buyers are down 19% when they buy, so make gauntlet gainz a minimum of 20%.
				emit onGauntletAcquired(msg.sender, amount, gType, end);
			} else if (gType == 3) {
				require(end <= 0x00ffffffffffffffffffffffffffffffffffffffff, "Invalid address");
				require(ExternalGauntletInterface(address(end)).gauntletRequirement(msg.sender, 0, amount), "External gauntlet check failed");
				emit onExternalGauntletAcquired(msg.sender, amount, address(end));
			} else {
				revert("Invalid gauntlet type");
			}
		} else if (oldGauntletType == 3) {
			require(gType == 3, "New gauntlet must be same type");
			require(end == gauntletEnd[msg.sender], "Must be same external gauntlet");
			require(ExternalGauntletInterface(address(end)).gauntletRequirement(msg.sender, oldGauntletBalance, amount), "External gauntlet check failed");
			emit onExternalGauntletAcquired(msg.sender, amount, address(end));
		} else {
			require(gType == oldGauntletType, "New gauntlet must be same type");
			require(end > oldGauntletEnd, "Gauntlet must be an upgrade");
			require(amount >= oldGauntletBalance, "New gauntlet must hold more tokens");
			emit onGauntletAcquired(msg.sender, amount, gType, end);
		}
	}

	function acquireExternalGauntlet(uint256 amount, address extGauntlet) public{
		acquireGauntlet(amount, 3, uint256(extGauntlet));
	}

	// Throw your money at this thing with a referrer specified by their Ethereum address.
	// Returns the amount of tokens created.
	function buy(address referrerAddress) payable public returns(uint256) {
		// Now, sending ETH increases the balance _before_ the transaction has been fully processed.
		// We don&#39;t want to distribute the entire purchase order as dividends.
		if (msg.value > 0) {
			lastTotalBalance += msg.value;
			distributeDividends(0, NULL_ADDRESS);
			lastTotalBalance -= msg.value;
		}
		return createTokens(msg.sender, msg.value, referrerAddress, false);
	}

	// I&#39;m only copy/pasting these functions due to the stack limit.
	// Throw your money at this thing with a referrer specified by their team JUST playerbook name.
	// Returns the amount of tokens created.
	function buy(string memory referrerName) payable public playerBookEnabled returns(uint256) {
		address referrerAddress = getAddressFromReferralName(referrerName);
		// As I said before, we don&#39;t want to distribute the entire purchase order as dividends.
		if (msg.value > 0) {
			lastTotalBalance += msg.value;
			distributeDividends(0, NULL_ADDRESS);
			lastTotalBalance -= msg.value;
		}
		return createTokens(msg.sender, msg.value, referrerAddress, false);
	}

	// Use all the ETH you earned hodling P3X to buy more P3X.
	// Returns the amount of tokens created.
	function reinvest() public returns(uint256) {
		address accountHolder = msg.sender;
		distributeDividends(0, NULL_ADDRESS); // Just in case P3D-only transactions happened.
		uint256 payout;
		uint256 bonusPayout;
		(payout, bonusPayout) = clearDividends(accountHolder);
		emit onWithdraw(accountHolder, payout, bonusPayout, true);
		return createTokens(accountHolder, payout + bonusPayout, NULL_ADDRESS, true);
	}

	// Use some of the ETH you earned hodling P3X to buy more P3X.
	// You can withdraw the rest or keept it in here allocated for you.
	// Returns the amount of tokens created.
	function reinvestPartial(uint256 ethToReinvest, bool withdrawAfter) public returns(uint256 tokensCreated) {
		address payable accountHolder = msg.sender;
		distributeDividends(0, NULL_ADDRESS); // Just in case P3D-only transactions happened.

		uint256 payout = dividendsOf(accountHolder, false);
		uint256 bonusPayout = bonuses[accountHolder];

		uint256 payoutReinvested = 0;
		uint256 bonusReinvested;

		require((payout + bonusPayout) >= ethToReinvest, "Insufficient balance for reinvestment");
		// We&#39;re going to take ETH out of the masternode bonus first, then the outstanding divs.
		if (ethToReinvest > bonusPayout){
			payoutReinvested = ethToReinvest - bonusPayout;
			bonusReinvested = bonusPayout;
			// Take ETH out from outstanding dividends.
			payouts[accountHolder] += int256(payoutReinvested * ROUNDING_MAGNITUDE);
		}else{
			bonusReinvested = ethToReinvest;
		}
		// Take ETH from the masternode bonus.
		bonuses[accountHolder] -= bonusReinvested;

		emit onWithdraw(accountHolder, payoutReinvested, bonusReinvested, true);
		// Do the buy thing!
		tokensCreated = createTokens(accountHolder, ethToReinvest, NULL_ADDRESS, true);

		if (withdrawAfter && dividendsOf(msg.sender, true) > 0) {
			withdrawDividends(msg.sender);
		}
		return tokensCreated;
	}

	// I&#39;m just a man who loves "default variables"
	function reinvestPartial(uint256 ethToReinvest) public returns(uint256) {
		return reinvestPartial(ethToReinvest, true);
	}

	// There&#39;s literally no reason to call this function
	function sell(uint256 amount, bool withdrawAfter) public returns(uint256) {
		require(amount > 0, "You have to sell something");
		uint256 sellAmount = destroyTokens(msg.sender, amount);
		if (withdrawAfter && dividendsOf(msg.sender, true) > 0) {
			withdrawDividends(msg.sender);
		}
		return sellAmount;
	}

	// Again with the default variables!
	function sell(uint256 amount) public returns(uint256) {
		require(amount > 0, "You have to sell something");
		return destroyTokens(msg.sender, amount);
	}

	// Transfer the sender&#39;s masternode bonuses and their outstanding divs to their wallet.
	function withdraw() public{
		require(dividendsOf(msg.sender, true) > 0, "No dividends to withdraw");
		withdrawDividends(msg.sender);
	}

	// There&#39;s definitely no reason to call this function
	function exit() public{
		address payable accountHolder = msg.sender;
		uint256 balance = balances[accountHolder];
		if (balance > 0) {
			destroyTokens(accountHolder, balance);
		}
		if (dividendsOf(accountHolder, true) > 0) {
			withdrawDividends(accountHolder);
		}
	}

	// Since website won&#39;t be released on launch, provide something on etherscan which will allow users to easily set masternodes.
	function setReferrer(address ref) public{
		savedReferral[msg.sender] = ref;
	}

	// Same as above except using the team JUST player book
	function setReferrer(string memory refName) public{
		savedReferral[msg.sender] = getAddressFromReferralName(refName);
	}

	// Another P3X selling point: Get P3X-exclusive didvidends _combined with_ P3D dividends!
	function donateDividends() payable public{
		distributeDividends(0, NULL_ADDRESS);
		emit onDonatedDividends(msg.sender, msg.value);
	}

	// --Public write functions--

	// --Public read-only functions

	// Returns the P3D address.
	function baseHourglass() external view returns(address) {
		return address(hourglass);
	}

	// Returns the salve account address (was mostly used for debugging purposes)
	function refHandlerAddress() external view returns(address) {
		return address(refHandler);
	}

	// Get someone&#39;s address from their team JUST playerbook name
	function getAddressFromReferralName(string memory refName) public view returns (address){
		return playerBook.getPlayerAddr(playerBook.pIDxName_(stringToBytes32(refName)));
	}

	// Retruns an addresses gauntlet type.
	function gauntletTypeOf(address accountHolder) public view returns(uint stakeAmount, uint gType, uint end) {
		if (isGauntletExpired(accountHolder)) {
			return (0, 0, gauntletEnd[accountHolder]);
		} else {
			return (gauntletBalance[accountHolder], gauntletType[accountHolder], gauntletEnd[accountHolder]);
		}
	}

	// Same as above except for msg.sender
	function myGauntletType() public view returns(uint stakeAmount, uint gType, uint end) {
		return gauntletTypeOf(msg.sender);
	}

	// Returns an addresse&#39;s P3X balance minus what they have in their gauntlet.
	function usableBalanceOf(address accountHolder) public view returns(uint balance) {
		if (isGauntletExpired(accountHolder)) {
			return balances[accountHolder];
		} else {
			return balances[accountHolder].sub(gauntletBalance[accountHolder]);
		}
	}

	// Same as above except for msg.sender
	function myUsableBalance() public view returns(uint balance) {
		return usableBalanceOf(msg.sender);
	}

	// I mean, every ERC20 token has this function. I&#39;m sure you know what it does.
	function balanceOf(address accountHolder) external view returns(uint balance) {
		return balances[accountHolder];
	}

	// Same as above except for msg.sender
	function myBalance() public view returns(uint256) {
		return balances[msg.sender];
	}

	// See if the specified sugardaddy allows the spender to spend their tokens
	function allowance(address sugardaddy, address spender) external view returns(uint remaining) {
		return allowances[sugardaddy][spender];
	}

	// Returns all the ETH that this contract has access to
	function totalBalance() public view returns(uint256) {
		return address(this).balance + hourglass.myDividends(true) + refHandler.totalBalance();
	}

	// Returns the ETH the specified address is owed.
	function dividendsOf(address customerAddress, bool includeReferralBonus) public view returns(uint256) {
		uint256 divs = uint256(int256(profitPerShare * balances[customerAddress]) - payouts[customerAddress]) / ROUNDING_MAGNITUDE;
		if (includeReferralBonus) {
			divs += bonuses[customerAddress];
		}
		return divs;
	}

	// Same as above except includes the masternode bonus
	function dividendsOf(address customerAddress) public view returns(uint256) {
		return dividendsOf(customerAddress, true);
	}

	// Alias of dividendsOf(msg.sender)
	function myDividends() public view returns(uint256) {
		return dividendsOf(msg.sender, true);
	}

	// Alias of dividendsOf(msg.sender, includeReferralBonus)
	function myDividends(bool includeReferralBonus) public view returns(uint256) {
		return dividendsOf(msg.sender, includeReferralBonus);
	}

	// Returns the masternode earnings of a specified account
	function refBonusOf(address customerAddress) external view returns(uint256) {
		return bonuses[customerAddress];
	}

	// Same as above xcept with msg.sender
	function myRefBonus() external view returns(uint256) {
		return bonuses[msg.sender];
	}

	// Backwards compatibility with the P3D interface
	function stakingRequirement() external view returns(uint256) {
		return referralRequirement;
	}

	// Backwards compatibility with the P3D interface
	function calculateTokensReceived(uint256 ethereumToSpend) public view returns(uint256) {
		return hourglass.calculateTokensReceived(ethereumToSpend);
	}

	// Backwards compatibility with the P3D interface
	function calculateEthereumReceived(uint256 tokensToSell) public view returns(uint256) {
		return hourglass.calculateEthereumReceived(tokensToSell);
	}
	// --Public read-only functions--

	// Internal functions

	// Returns true if the gauntlet has expired. Otherwise, false.
	function isGauntletExpired(address holder) internal view returns(bool) {
		if (gauntletType[holder] != 0) {
			if (gauntletType[holder] == 1) {
				return (block.timestamp >= gauntletEnd[holder]);
			} else if (gauntletType[holder] == 2) {
				return (hourglass.totalSupply() >= gauntletEnd[holder]);
			} else if (gauntletType[holder] == 3) {
				return ExternalGauntletInterface(gauntletEnd[holder]).gauntletRemovable(holder);
			}
		}
		return false;
	}

	// Same as usableBalanceOf, except the gauntlet is lifted when it&#39;s expired.
	function updateUsableBalanceOf(address holder) internal returns(uint256) {
		// isGauntletExpired is a _view_ function, with uses STATICCALL in solidity 0.5.0 or later.
		// Since STATICCALLs can&#39;t modifiy the state, re-entry attacks aren&#39;t possible here.
		if (isGauntletExpired(holder)) {
			if (gauntletType[holder] == 3){
				emit onExternalGauntletAcquired(holder, 0, NULL_ADDRESS);
			}else{
				emit onGauntletAcquired(holder, 0, 0, 0);
			}
			gauntletType[holder] = 0;
			gauntletBalance[holder] = 0;

			return balances[holder];
		}
		return balances[holder] - gauntletBalance[holder];
	}

	// This is the actual buy function
	function createTokens(address creator, uint256 eth, address referrer, bool reinvestment) internal returns(uint256) {
		// Let&#39;s not call the parent hourglass all the time.
		uint256 parentReferralRequirement = hourglass.stakingRequirement();
		// How much ETH will be given to the referrer if there is one.
		uint256 referralBonus = eth / HOURGLASS_FEE / HOURGLASS_BONUS;

		bool usedHourglassMasternode = false;
		bool invalidMasternode = false;
		if (referrer == NULL_ADDRESS) {
			referrer = savedReferral[creator];
		}

		// Solidity has limited amount of local variables, so the memory allocated to this one gets reused for other purposes later.
		//uint256 refHandlerBalance = hourglass.balanceOf(address(refHandler));
		uint256 tmp = hourglass.balanceOf(address(refHandler));

		// Let&#39;s once again pretend this actually prevents people from cheating.
		if (creator == referrer) {
			// Tell everyone that no referral purchase was made because cheating (unlike P3D)
			invalidMasternode = true;
		} else if (referrer == NULL_ADDRESS) {
			usedHourglassMasternode = true;
		// Make sure that the referrer has enough funds to _be_ a referrer, and make sure that we have our own P3D masternode to get that extra ETH
		} else if (balances[referrer] >= referralRequirement && (tmp >= parentReferralRequirement || hourglass.balanceOf(address(this)) >= parentReferralRequirement)) {
			// It&#39;s a valid P3X masternode, hooray! (do nothing)
		} else if (hourglass.balanceOf(referrer) >= parentReferralRequirement) {
			usedHourglassMasternode = true;
		} else {
			// Tell everyone that no referral purchase was made because not enough balance (again, unlike P3D)
			invalidMasternode = true;
		}

		// Thanks to Crypto McPump for helping me _not_ waste gas here.
		/*
		uint256 createdTokens = hourglass.calculateTokensReceived(eth); // See? Look how much gas I would have wasted.
		totalSupply += createdTokens;
		*/
		uint256 createdTokens = hourglass.totalSupply();

		// KNOWN BUG: If lord Justo increases the staking requirement to something above both of the contract&#39;s P3D
		// balance, then all masternodes won&#39;t work until there are enough buy orders to make the refHandler&#39;s P3D
		// balance above P3D&#39;s masternode requirement.

		// if the refHandler hass less P3D than P3D&#39;s masternode requirement, then it should buy the tokens.
		if (tmp < parentReferralRequirement) {
			if (reinvestment) {
				// We need to know if the refHandler has enough ETH to do the reinvestment on its own
				//uint256 refHandlerEthBalance = refHandler.totalBalance();
				tmp = refHandler.totalBalance();
				if (tmp < eth) {
					// If it doesn&#39;t, then we must transfer it the remaining ETH it needs.
					tmp = eth - tmp; // fundsToGive = eth - refHandlerEthBalance;
					if (address(this).balance < tmp) {
						// If this fails, something went horribly wrong because the client is attempting to reinvest more ethereum than we&#39;ve got
						hourglass.withdraw();
					}
					address(refHandler).transfer(tmp);
				}
				tmp = hourglass.balanceOf(address(refHandler));

				// Reinvestments are always done using the null referrer
				refHandler.buyTokensFromBalance(NULL_ADDRESS, eth);
			} else {
				// these nested ? statements are only here because I can only have a limited amount of local variables.
				// Forward the ETH we were sent to the refHandler to place the buy order.
				refHandler.buyTokens.value(eth)(invalidMasternode ? NULL_ADDRESS : (usedHourglassMasternode ? referrer : address(this)));
			}
		} else {
			if (reinvestment) {
				// If we don&#39;t have enough ETH to do the reinvestment, withdraw.
				if (address(this).balance < eth && hourglass.myDividends(true) > 0) {
					hourglass.withdraw();
				}
				// If we _still_ don&#39;t have enough ETH to do the reinvestment, have the refHandler sends us some.
				if (address(this).balance < eth) {
					refHandler.sendETH(address(this), eth - address(this).balance);
				}
			}
			hourglass.buy.value(eth)(invalidMasternode ? NULL_ADDRESS : (usedHourglassMasternode ? referrer : address(refHandler)));
		}

		// Use the delta from before and after the buy order to get the amount of P3D created.
		createdTokens = hourglass.totalSupply() - createdTokens;
		totalSupply += createdTokens;

		// This is here for when someone transfers P3D to the contract directly. We have no way of knowing who it&#39;s from, so we&#39;ll just give it to the next person who happens to buy.
		uint256 bonusTokens = hourglass.myTokens() + tmp - totalSupply;

		// Here I now re-use that uint256 to create the bit flags.
		tmp = 0;
		if (invalidMasternode)			{ tmp |= 1; }
		if (usedHourglassMasternode)	{ tmp |= 2; }
		if (reinvestment)				{ tmp |= 4; }

		emit onTokenPurchase(creator, eth, createdTokens, bonusTokens, referrer, uint8(tmp));
		createdTokens += bonusTokens;
		// We can finally give the P3X to the buyer!
		balances[creator] += createdTokens;
		totalSupply += bonusTokens;

		//Updates services like etherscan which track token hodlings.
		emit Transfer(address(this), creator, createdTokens, "");
		emit Transfer(address(this), creator, createdTokens);

		// Unfortunatly, SafeMath cannot be used here, otherwise the stack gets too deep
		payouts[creator] += int256(profitPerShare * createdTokens); // You don&#39;t deserve the dividends before you owned the tokens.

		if (reinvestment) {
			// No dividend distribution underflows allowed.
			// Ethereum has been given away after a "reinvestment" purchase, so we have to keep track of that.
			lastTotalBalance = lastTotalBalance.sub(eth);
		}
		distributeDividends((usedHourglassMasternode || invalidMasternode) ? 0 : referralBonus, referrer);
		if (referrer != NULL_ADDRESS) {
			// Save the referrer for next time!
			savedReferral[creator] = referrer;
		}
		return createdTokens;
	}

	// This is marked as an internal function because selling could have been the result of transfering P3X to the contract via a transferFrom transaction.
	function destroyTokens(address weakHand, uint256 bags) internal returns(uint256) {
		require(updateUsableBalanceOf(weakHand) >= bags, "Insufficient balance");

		// Give the weak hand the last of their deserved payout.
		// Also updates lastTotalBalance
		distributeDividends(0, NULL_ADDRESS);
		uint256 tokenBalance = hourglass.myTokens();

		// We can&#39;t rely on ETH balance delta because we get cut of the sell fee ourselves.
		uint256 ethReceived = hourglass.calculateEthereumReceived(bags);
		lastTotalBalance += ethReceived;
		if (tokenBalance >= bags) {
			hourglass.sell(bags);
		} else {
			// If we don&#39;t have enough P3D to sell ourselves, get the slave to sell some, too.
			if (tokenBalance > 0) {
				hourglass.sell(tokenBalance);
			}
			refHandler.sellTokens(bags - tokenBalance);
		}

		// Put the ETH in outstanding dividends, and allow the weak hand access to the divs they&#39;ve accumilated before they sold.
		int256 updatedPayouts = int256(profitPerShare * bags + (ethReceived * ROUNDING_MAGNITUDE));
		payouts[weakHand] = payouts[weakHand].sub(updatedPayouts);

		// We already checked the balance of the weakHanded person, so SafeMathing here is redundant.
		balances[weakHand] -= bags;
		totalSupply -= bags;

		emit onTokenSell(weakHand, bags, ethReceived);

		// Tell etherscan of this tragity.
		emit Transfer(weakHand, address(this), bags, "");
		emit Transfer(weakHand, address(this), bags);
		return ethReceived;
	}

	// sends ETH to the specified account, using all the ETH P3X has access to.
	function sendETH(address payable to, uint256 amount) internal {
		uint256 childTotalBalance = refHandler.totalBalance();
		uint256 thisBalance = address(this).balance;
		uint256 thisTotalBalance = thisBalance + hourglass.myDividends(true);
		if (childTotalBalance >= amount) {
			// the refHanlder has enough of its own ETH to send, so it should do that.
			refHandler.sendETH(to, amount);
		} else if (thisTotalBalance >= amount) {
			// We have enough ETH of our own to send.
			if (thisBalance < amount) {
				hourglass.withdraw();
			}
			to.transfer(amount);
		} else {
			// Neither we nor the refHandler has enough ETH to send individually, so both contracts have to send ETH.
			refHandler.sendETH(to, childTotalBalance);
			if (hourglass.myDividends(true) > 0) {
				hourglass.withdraw();
			}
			to.transfer(amount - childTotalBalance);
		}
		// keep the dividend tracker in check.
		lastTotalBalance = lastTotalBalance.sub(amount);
	}

	// Take the ETH we&#39;ve got and distribute it among our token holders.
	function distributeDividends(uint256 bonus, address bonuser) internal{
		// Prevents "HELP I WAS THE LAST PERSON WHO SOLD AND I CAN&#39;T WITHDRAW MY ETH WHAT DO????" (dividing by 0 results in a crash)
		if (totalSupply > 0) {
			uint256 tb = totalBalance();
			uint256 delta = tb - lastTotalBalance;
			if (delta > 0) {
				// We have more ETH than before, so we&#39;ll just distribute those dividends among our token holders.
				if (bonus != 0) {
					bonuses[bonuser] += bonus;
				}
				profitPerShare = profitPerShare.add(((delta - bonus) * ROUNDING_MAGNITUDE) / totalSupply);
				lastTotalBalance += delta;
			}
		}
	}

	// Clear out someone&#39;s dividends.
	function clearDividends(address accountHolder) internal returns(uint256, uint256) {
		uint256 payout = dividendsOf(accountHolder, false);
		uint256 bonusPayout = bonuses[accountHolder];

		payouts[accountHolder] += int256(payout * ROUNDING_MAGNITUDE);
		bonuses[accountHolder] = 0;

		// External apps can now get reliable masternode statistics
		return (payout, bonusPayout);
	}

	// Withdraw 100% of someone&#39;s dividends
	function withdrawDividends(address payable accountHolder) internal {
		distributeDividends(0, NULL_ADDRESS); // Just in case P3D-only transactions happened.
		uint256 payout;
		uint256 bonusPayout;
		(payout, bonusPayout) = clearDividends(accountHolder);
		emit onWithdraw(accountHolder, payout, bonusPayout, false);
		sendETH(accountHolder, payout + bonusPayout);
	}

	// The internal transfer function.
	function actualTransfer (address payable from, address payable to, uint value, bytes memory data, string memory func, bool careAboutHumanity) internal{
		require(updateUsableBalanceOf(from) >= value, "Insufficient balance");
		require(to != address(refHandler), "My slave doesn&#39;t get paid"); // I don&#39;t know why anyone would do this, but w/e
		require(to != address(hourglass), "P3D has no need for these"); // Prevent l33x h4x0rs from having P3X call arbitrary P3D functions.

		if (to == address(this)) {
			// Treat transfers to this contract as a sell and withdraw order.
			if (value == 0) {
				// Transfers of 0 still have to be emitted... for some reason.
				emit Transfer(from, to, value, data);
				emit Transfer(from, to, value);
			} else {
				destroyTokens(from, value);
			}
			withdrawDividends(from);
		} else {
			distributeDividends(0, NULL_ADDRESS); // Just in case P3D-only transactions happened.
			// I was going to add a value == 0 check here, but if you&#39;re sending 0 tokens to someone, you deserve to pay for wasted gas.

			// Throwing an exception undos all changes. Otherwise changing the balance now would be a shitshow
			balances[from] = balances[from].sub(value);
			balances[to] = balances[to].add(value);

			// Sender can have their dividends from when they owned the tokens
			payouts[from] -= int256(profitPerShare * value);
			// Receiver is not allowed to have dividends from before they owned the tokens.
			payouts[to] += int256(profitPerShare * value);

			if (careAboutHumanity && isContract(to)) {
				if (bytes(func).length == 0) {
					ERC223Handler receiver = ERC223Handler(to);
					receiver.tokenFallback(from, value, data);
				} else {
					bool success;
					bytes memory returnData;
					(success, returnData) = to.call.value(0)(abi.encodeWithSignature(func, from, value, data));
					assert(success);
				}
			}
			emit Transfer(from, to, value, data);
			emit Transfer(from, to, value);
		}
	}

	// The playerbook contract accepts a bytes32. We&#39;ll be converting for convenience sense.
	function bytesToBytes32(bytes memory data) internal pure returns(bytes32){
		uint256 result = 0;
		uint256 len = data.length;
		uint256 singleByte;
		for (uint256 i = 0; i<len; i+=1){
			singleByte = uint256(uint8(data[i])) << ( (31 - i) * 8);
			require(singleByte != 0, "bytes cannot contain a null byte");
			result |= singleByte;
		}
		return bytes32(result);
	}

	// haha casting types.
	function stringToBytes32(string memory data) internal pure returns(bytes32){
		return bytesToBytes32(bytes(data));
	}

	// If bytecode exists at _addr then the _addr is a contract.
	function isContract(address _addr) internal view returns(bool) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		return (length>0);
	}

	// Reject possible accidental sendin of higher-tech shitcoins. (with a fancy message)
	function tokenFallback(address from, uint value, bytes memory data) public pure{
		revert("I don&#39;t want your shitcoins!");
	}

	// Allow anyone else to take forcefully sent low-tech shitcoins. (I sure as hell don&#39;t want them)
	function takeShitcoin(address shitCoin) public{
		// Don&#39;t allow people to siphon funds from us
		require(shitCoin != address(hourglass), "P3D isn&#39;t a shitcoin");
		ERC20interface s = ERC20interface(shitCoin);
		s.transfer(msg.sender, s.balanceOf(address(this)));
	}
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
		if (a == 0 || b == 0) {
		   return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}

	/**
	* @dev Subtracts two numbers, throws on underflow
	*/
	function sub(int256 a, int256 b) internal pure returns(int256 c) {
		c = a - b;
		assert(c <= a);
		return c;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(int256 a, int256 b) internal pure returns(int256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}