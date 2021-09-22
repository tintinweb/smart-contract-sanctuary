// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./interfaces/IFracTokenVault.sol";
import "./interfaces/IFracVaultFactory.sol";
import "./interfaces/INounsAuctionHouse.sol";
import "./interfaces/INounsParty.sol";
import "./interfaces/INounsToken.sol";

/**
 * @title NounsParty contract
 * @author twitter.com/devloper_eth
 * @notice Nouns party is an effort aimed at making community-driven nouns bidding easier, more interactive, and more likely to win than today's strategies.
 */
// solhint-disable max-states-count
contract NounsParty is
	INounsParty,
	Initializable,
	OwnableUpgradeable,
	PausableUpgradeable,
	ReentrancyGuardUpgradeable,
	UUPSUpgradeable
{
	uint256 private constant ETH1_1000 = 1_000_000_000_000_000; // 0.001 eth
	uint256 private constant ETH1_10 = 100_000_000_000_000_000; // 0.1 eth

	/// @dev post fractionalized token fee
	uint256 public nounsPartyFee;

	/// @dev max increase in percent for bids
	uint256 public bidIncrease;
	uint256 public nounsAuctionHouseBidIncrease;

	/// @notice pendingSettledCount is > 0 if there are outstanding auctions that need to be settled
	/// @dev withdraw is blocked if pendingSettledCount > 0
	uint256 public pendingSettledCount;

	/// @dev settledList head and tail cursor
	uint256 public settledListHead;
	uint256 public settledListTail;

	/**
	 * @dev poolWriteCursor is a global cursor indicating where to write in `pool`.
	 *      For each new deposit to `pool` it will increase by 1.
	 *      Read more in deposit().
	 */
	uint256 private poolWriteCursor;

	/// @dev poolReadCursor is a "global" cursor indicating which position to read next from the pool.
	uint256 private poolReadCursor;

	/// @notice the balance of all deposits
	uint256 public depositBalance;

	/// @dev linked list of nounIds that need to be settled
	mapping(uint256 => uint256) public settledList;

	/// @dev use deposits() to read pool
	mapping(uint256 => Deposit) private pool;

	/// @notice bids stores the latest bid for a given noun, mapping(nounId) => bidAmount
	/// @dev bids[noundId] is deleted after settle is called
	mapping(uint256 => uint256) public bids;

	/// @notice claims has information about who can claim NOUN tokens after a successful auction
	/// @dev claims is populated in _depositsToClaims()
	mapping(address => TokenClaim[]) public claims;

	/// @notice map nounIds to fractionalize.art token vaults,  mapping(nounId) => fracTokenVaultAddress
	/// @dev only holds mappings for won auctions, but stores it forever. mappings aren't deleted. TokenClaims rely on fracTokenVaults - addresses should never change after first write.
	mapping(uint256 => address) public fracTokenVaults;

	address public fracVaultFactoryAddress;
	address public nounsPartyCuratorAddress;
	address public nounsPartyTreasuryAddress;
	address public nounsTokenAddress;

	INounsAuctionHouse public nounsAuctionHouse;
	INounsToken public nounsToken;
	IFracVaultFactory public fracVaultFactory;

	/// @dev is bid function allowed?
	bool public allowBid;

	function initialize(
		address _nounsAuctionHouseAddress,
		address _nounsTokenAddress,
		address _fracVaultFactoryAddress,
		address _nounsPartyCuratorAddress,
		address _nounsPartyTreasuryAddress,
		uint256 _nounsAuctionHouseBidIncrease
	) public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
		__ReentrancyGuard_init();
		__Pausable_init();

		require(_nounsAuctionHouseAddress != address(0), "zero nounsAuctionHouseAddress");
		require(_nounsTokenAddress != address(0), "zero nounsTokenAddress");
		require(_fracVaultFactoryAddress != address(0), "zero fracVaultFactoryAddress");
		require(_nounsPartyCuratorAddress != address(0), "zero nounsPartyCuratorAddress");
		require(_nounsPartyTreasuryAddress != address(0), "zero nounsPartyTreasuryAddress");

		nounsTokenAddress = _nounsTokenAddress;
		nounsPartyCuratorAddress = _nounsPartyCuratorAddress;
		fracVaultFactoryAddress = _fracVaultFactoryAddress;
		nounsPartyTreasuryAddress = _nounsPartyTreasuryAddress;
		nounsAuctionHouse = INounsAuctionHouse(_nounsAuctionHouseAddress);
		nounsToken = INounsToken(_nounsTokenAddress);
		fracVaultFactory = IFracVaultFactory(_fracVaultFactoryAddress);

		poolWriteCursor = 1; // must start at 1
		poolReadCursor = 1; // must start at 1

		pendingSettledCount = 0;
		settledListHead = 0;
		settledListTail = 0;

		allowBid = true;

		nounsPartyFee = 25; // 2.5%

		/// @dev min bid increase percentages
		bidIncrease = 50; // 5%
		nounsAuctionHouseBidIncrease = _nounsAuctionHouseBidIncrease; // 2% in mainnet, 5% in rinkeby (Sep 2020)
	}

	/// @notice Puts ETH into our bidding pool.
	/// @dev Using `pool` and `poolWriteCursor` we keep track of deposit ordering over time.
	function deposit() external payable override nonReentrant whenNotPaused {
		require(msg.sender != address(0), "zero msg.sender");

		// Verify deposit amount to ensure fractionalizing will produce whole numbers.
		require(msg.value % ETH1_1000 == 0, "Must be in 0.001 ETH increments");

		// v0 asks for a 0.1 eth minimum deposit.
		// v1 will ask for 0.001 eth as minimum deposit.
		require(msg.value >= ETH1_10, "Minimum deposit is 0.1 ETH");

		// v0 caps the number of deposits at 250, to prevent too costly settle calls.
		// v1 will lift this cap.
		require(poolWriteCursor - poolReadCursor < 250, "Too many deposits");

		// Create a new deposit and add it to the pool.
		Deposit memory d = Deposit({ owner: msg.sender, amount: msg.value });
		pool[poolWriteCursor] = d;

		// poolWriteCursor is never reset and continuously increases over the lifetime of this contract.
		// Solidity checks for overflows, in which case the deposit would safely revert and a new contract would have to be deployed.
		// But hey, poolWriteCursor is of type uint256 which is a really really really big number (2^256-1 to be exact).
		// Considering that the minimum bid is 0.001 ETH + gas cost, which would make a DOS attack very expensive at current price rates,
		// we should never see poolWriteCursor overflow.
		// Ah, poolReadCursor which follows poolWriteCursor faces the same fate.
		//
		// Why not use an array you might ask? Our logic would cause gaps in our array to form over time,
		// causing unnecessary/expensive index lookups and shifts. `pool` is essentially a mapping turned
		// into an ordered array, using poolWriteCursor as sequential index.
		poolWriteCursor++;

		// Increase deposit balance
		depositBalance = depositBalance + msg.value;

		emit LogDeposit(msg.sender, msg.value);
	}

	/// @notice Bid for the given noun's auction.
	/// @dev Bid amounts don't have to be in 0.001 ETH increments, just deposits.
	function bid() external payable override nonReentrant whenNotPaused {
		require(allowBid, "Bidding disabled");

		(uint256 nounId, uint256 amount, address bidder, bool settled) = _maxBid();
		require(!settled, "Inactive auction");
		require(bidder != address(this), "Already winning");
		require(pendingSettledCount == 0 || (pendingSettledCount == 1 && nounId == settledListTail), "Settle previous auction first");

		// To ensure if we ever treated 0 as "zero noun", we prevent 0 to enter our contract in the first place.
		// This isn't necessary, but defensive programming. Noun0 has been minted a long time ago, so this is ok.
		require(nounId > 0, "zero noun");

		require(amount >= ETH1_1000, "Minimum bid is 0.001 ETH");
		require(depositBalance >= amount, "Insufficient funds");
		require(amount > bids[nounId], "Minimum bid not reached");

		// We should never see this error, because we are always checking
		// depositBalance, not the contracts' balance. Checking just in case.
		require(address(this).balance >= amount, "Insufficient balance");

		// first time bidding on nounId? set settledList and increase count
		if (settledListTail < nounId) {
			settledList[settledListTail] = nounId;
			settledListTail = nounId;
			pendingSettledCount++;
		}

		// Set the new bid
		bids[nounId] = amount;

		emit LogBid(nounId, amount, msg.sender);

		// And finally submit bid to nouns auction house. Fingers crossed.
		nounsAuctionHouse.createBid{ value: amount }(nounId);
	}

	/// @dev returns the next noun id to be settled
	/// @return next noun Id to settle
	function settleNext() external view override returns (uint256) {
		return _settleNext();
	}

	/// @dev see settleNext()
	function _settleNext() private view returns (uint256) {
		uint256 head = settledList[settledListHead];
		require(head > 0, "Nothing to settle");
		return head;
	}

	/// @dev calls _settleNext but won't revert for `0`.
	///      Why? Our frontend uses package `EthWorks/useDApp`, which uses Multicall v1.
	///      Multicall v1 will fail if just one out of many calls fails.
	///      See also https://github.com/EthWorks/useDApp/issues/334.
	///      Please note that this workaround function does NOT affect
	///      the integrity or security of this contract.
	function settleNextWhichDoesntRevertAsMulticallWorkaround() external view returns (uint256) {
		return settledList[settledListHead];
	}

	/// @notice Settles an auction.
	/// @dev Needs to be called after every auction to determine if we won or lost, and create token claims if we won.
	function settle() external override nonReentrant whenNotPaused {
		uint256 nounId = _settleNext();

		// Noun, what's your status?
		NounStatus status = _nounStatus(nounId);

		// Oh look, we won!!! :tada:
		if (status == NounStatus.WON) {
			uint256 amount = bids[nounId];
			delete bids[nounId];
			pendingSettledCount--;
			settledListHead = nounId;
			emit LogSettleWon(nounId);

			// Turn NFT into ERC20 tokens
			(address fracTokenVaultAddress, uint256 fee) = _fractionalize(
				amount, // bid amount
				nounId
			);

			// Map nounId to fractionalize's token vault address.
			// Set once, never update. Otherwise TokenClaims get confused and map to a different token vault.
			fracTokenVaults[nounId] = fracTokenVaultAddress;

			// Turn deposits into token claims.
			_depositsToClaims(amount, nounId);

			// Send fee to our treasury wallet.
			IFracTokenVault fracTokenVault = IFracTokenVault(fracTokenVaultAddress);
			require(fracTokenVault.transfer(nounsPartyTreasuryAddress, fee), "Fee transfer failed");
			return;
		}

		// We didn't win, because Noun was burned, or we just lost.
		if (status == NounStatus.BURNED || status == NounStatus.LOST) {
			delete bids[nounId];
			pendingSettledCount--;
			settledListHead = nounId; // solhint-disable reentrancy
			emit LogSettleLost(nounId);
			return;
		}

		if (status == NounStatus.MINTED) {
			revert("Noun not sold yet");
		} else if (status == NounStatus.NOTFOUND) {
			revert("Noun not found");
		} else {
			revert("Unknown Noun Status"); // for anything else
		}
	}

	/// @notice Claim tokens from won auctions
	/// @dev nonReentrant is very important here to prevent Reentrancy.
	function claim() external override nonReentrant whenNotPaused {
		require(msg.sender != address(0), "zero msg.sender");

		// Iterate over all claims for msg.sender and transfer tokens.
		uint256 length = claims[msg.sender].length;
		for (uint256 index = 0; index < length; index++) {
			TokenClaim memory c = claims[msg.sender][index];
			address fracTokenVaultAddress = fracTokenVaults[c.nounId];
			require(fracTokenVaultAddress != address(0), "zero fracTokenVault address");

			emit LogClaim(msg.sender, c.nounId, fracTokenVaultAddress, c.tokens / uint256(1 ether));

			IFracTokenVault fracTokenVault = IFracTokenVault(fracTokenVaultAddress);
			require(fracTokenVault.transfer(msg.sender, c.tokens), "Token transfer failed");
		}

		// Check-Effects-Interactions pattern can't be followed in this case, hence nonReentrant
		// is so important for this function.
		delete claims[msg.sender];
	}

	/// @notice Withdraw deposits that haven't been used to bid on a noun.
	/// @dev Withdrawals are only possible if no auctions need to be settled and if there isn't a "hot" auction.
	function withdraw() external payable override whenNotPaused nonReentrant {
		require(pendingSettledCount == 0, "Pending Settlements");
		require(!_auctionIsHot(), "Auction is hot");
		require(msg.sender != address(0), "zero msg.sender");

		// Calculate sum of all deposits from msg.sender.
		uint256 amount = 0;
		uint256 readCursor = poolReadCursor;
		while (readCursor <= poolWriteCursor) {
			if (pool[readCursor].owner == msg.sender) {
				amount = amount + pool[readCursor].amount;
				delete pool[readCursor]; // important: delete deposit to avoid double withdrawals
			}
			readCursor++;
		}

		require(amount > 0, "Insufficient funds");
		depositBalance = depositBalance - amount;
		emit LogWithdraw(msg.sender, amount);
		_transferETH(msg.sender, amount);
	}

	/// @dev Iterates over all deposits in `pool` and creates `claims` which then allows users to claim their tokens.
	function _depositsToClaims(uint256 _amount, uint256 _nounId) private {
		// Decrease depositBalance by amount
		depositBalance = depositBalance - _amount;

		// Use a temporary cursor here (to save gas), but write back to poolReadCursor at the end.
		uint256 readCursor = poolReadCursor;

		// Read until we iterated through the pool, but also have an eye on amount.
		// We can stop iterating if we already "filled" _amount with enough deposits.
		while (readCursor <= poolWriteCursor && _amount > 0) {
			// Delete and skip if deposit is zero
			if (pool[readCursor].owner == address(0) || pool[readCursor].amount == 0) {
				delete pool[readCursor]; // delete deposit, it's already zero'd out anyway.
				readCursor++;
				continue; // to the next deposit
			}

			// Can we use the full deposit amount?
			if (pool[readCursor].amount <= _amount) {
				// Reduce amount by this deposit's amount
				_amount = _amount - pool[readCursor].amount;

				// Create a token claim for depositor.
				TokenClaim memory t0 = TokenClaim({
					tokens: pool[readCursor].amount * 1000, // full amount of deposit turned into tokens
					nounId: _nounId
				});
				claims[pool[readCursor].owner].push(t0);

				// Delete deposit, to prevent multiple claims.
				delete pool[readCursor];
				readCursor++;
				continue; // to the next deposit
			}

			// If we reach this line, we know:
			// 1) _amount is > 0 and
			// 2) pool[readCursor].amount > 0 and
			// 3) pool[readCursor].amount > _amount

			// Create a token claim for depositor, but only with partial amounts and tokens.
			TokenClaim memory t1 = TokenClaim({
				tokens: _amount * 1000, // remaining _amount turned into tokens
				nounId: _nounId
			});
			claims[pool[readCursor].owner].push(t1);

			// Don't forget to update the original deposit with the reduced amount.
			pool[readCursor].amount = pool[readCursor].amount - _amount;

			// The math only checks out, if _amount equals 0 at the end.
			// Which means we 100% "filled" _amount.
			_amount = _amount - _amount;
			assert(_amount == 0);

			// Do not advance poolReadCursor for deposits that still have a balance.
			// So no `readCursor++` here!

			// Also, since _amount is now 0, we will exit from the while loop now.
		}

		// Write our temporary readCursor back to the state variable.
		poolReadCursor = readCursor;
	}

	/// @dev Calls fractional.art's contracts to turn a noun NFT into fractionalized ERC20 tokens.
	/// @param _amount cost of the noun
	/// @param _nounId noun id
	/// @return tokenVaultAddress ERC20 vault address
	/// @return fee how many tokens we keep as fee
	function _fractionalize(uint256 _amount, uint256 _nounId) private returns (address tokenVaultAddress, uint256 fee) {
		require(_amount >= ETH1_1000, "Amount must be >= 0.001 ETH");

		// symbol = "Noun" + _nounId, like Noun13, Noun14, ...
		string memory symbol = string(abi.encodePacked("Noun", StringsUpgradeable.toString(_nounId)));

		// Calculate token supply by integer division: _amount * 1000 / 1e18
		// Integer divisions round towards zero.
		// For example: 1.9 tokens would turn into 1 token.
		// This can lead to a minimal value inflation of the total supply by at max 0.9999... tokens,
		// which again is so small it's neglectable.
		uint256 supply = uint256(_amount * 1000) / uint256(1 ether);
		require(supply >= 1, "Fractionalization failed");

		// Calculate fee based on supply by integer division.
		// Integer division means we don't charge a fee for bids 0.04 or less.
		// For bids above 0.04 we minimally decrease our effective fee to produce whole numbers where necessary.
		fee = uint256(supply * 1000 * nounsPartyFee) / uint256(1000000);

		uint256 adjustedSupply = supply + fee;

		emit LogFractionalize(_nounId, adjustedSupply, fee);

		// Approve fractionalize.art to take over our noun NFT.
		nounsToken.approve(fracVaultFactoryAddress, _nounId);

		// Let fractionalize.art create some ERC20 tokens for us.
		uint256 vaultNumber = fracVaultFactory.mint(
			symbol,
			symbol,
			nounsTokenAddress,
			_nounId,
			(adjustedSupply) * 1 ether, // convert back to wei (1 eth == 1e18)
			_amount * 5, // listPrice is the the initial price of the NFT
			0 // annual management fee (see our fee instead)
		);

		// Set our curator address.
		tokenVaultAddress = fracVaultFactory.vaults(vaultNumber);
		IFracTokenVault(tokenVaultAddress).updateCurator(nounsPartyCuratorAddress);

		return (tokenVaultAddress, fee * 1 ether); // convert back to wei
	}

	/// @notice Deposits returns all available deposits.
	/// @dev Deposits reads from `pool` using a temporary readCursor.
	/// @return A list of all available deposits.
	function deposits() external view override returns (Deposit[] memory) {
		// Determine pool length so we can build a new fixed-size array.
		uint256 size = 0;
		uint256 readCursor = poolReadCursor;
		while (readCursor <= poolWriteCursor) {
			if (pool[readCursor].owner != address(0) && pool[readCursor].amount > 0) {
				size++;
			}
			readCursor++;
		}

		// Create a new fixed-size Deposit array.
		Deposit[] memory depos = new Deposit[](size);
		readCursor = poolReadCursor;
		uint256 cursor = 0;
		while (readCursor <= poolWriteCursor) {
			if (pool[readCursor].owner != address(0) && pool[readCursor].amount > 0) {
				depos[cursor] = pool[readCursor];
				cursor++;
			}
			readCursor++;
		}

		return depos;
	}

	/// @notice Indicates if a auction is about to start/live.
	/// @dev External because it "implements" the INounsParty interface.
	/// @return true if auction is live (aka hot).
	function auctionIsHot() external view override returns (bool) {
		return _auctionIsHot();
	}

	/// @dev Private _auctionIsHot() to allow private access from contract.
	/// @return true if auction is live (aka hot).
	function _auctionIsHot() private view returns (bool) {
		return false; // TODO rinkeby test deployment
		(, , , uint256 endTime, , bool settled) = nounsAuctionHouse.auction();

		// If auction has been settled, it can't be hot. Or we got a zero endTime?!
		if (settled || endTime == 0) {
			return false;
		}

		// Is this auction hot or not?
		// .......... [ -1 hour ............ endTime .. + 10 minutes ] ........
		// not hot    |--------------- hot --------------------------|  not hot
		// solhint-disable not-rely-on-time
		if (block.timestamp >= endTime - 1 hours && block.timestamp <= endTime + 10 minutes) {
			return true;
		}

		return false;
	}

	/// @dev Calculate the current max bid.
	function maxBid() external view override returns (uint256 _nounId, uint256 _amount) {
		(uint256 nounId, uint256 amount, , ) = _maxBid();
		return (nounId, amount);
	}

	/// @dev see maxBid
	function _maxBid()
		private
		view
		returns (
			uint256 _nounId,
			uint256 _amount,
			address _bidder,
			bool _settled
		)
	{
		(uint256 nounId, uint256 amount, , , address bidder, bool settled) = nounsAuctionHouse.auction();

		if (settled || bidder == address(this)) {
			return (nounId, 0, bidder, settled);
		}

		uint256 newBid = amount + ((amount * 1000 * (bidIncrease + nounsAuctionHouseBidIncrease)) / uint256(1000000));

		if (newBid == 0) {
			return (nounId, ETH1_10, bidder, settled);
		} else {
			newBid = newBid - (newBid % ETH1_1000); // must be in 0.001 ETH increments

			// If newBid is greater than the depositBalance, use full balance instead.
			if (newBid > depositBalance) {
				newBid = depositBalance;

				// must be in 0.001 ETH increments
				// shouldn't be necessary, but just to be safe.
				newBid = newBid - (newBid % ETH1_1000);

				// newBid must be greater than min nounsAuctionHouse bid increase though
				uint256 minBid = amount + ((amount * 1000 * (nounsAuctionHouseBidIncrease)) / uint256(1000000));
				if(newBid < minBid) {
					// can't bid, return 0.
					return (nounId, 0, bidder, settled);
				}
			}

			return (nounId, newBid, bidder, settled);
		}
	}

	/// @dev Check the `ownerOf` a noun to check its status.
	/// @return NounStatus, which is either WON, BURNED, MINTED, LOST or NOTFOUND.
	function _nounStatus(uint256 _nounId) private returns (NounStatus) {
		// Life cycle of a noun, relevant in this context:
		// 1. A new noun is minted:
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/NounsToken.sol#L149
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/NounsToken.sol#L258
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/base/ERC721.sol#L321

		// 2. Auction is settled, meaning the noun is either burned (nobody bid on it) or transfered to highest bidder.
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/NounsAuctionHouse.sol#L221
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/base/ERC721.sol#L182

		try nounsToken.ownerOf(_nounId) returns (address nounOwner) {
			if (nounOwner == address(this)) {
				// address(this) - that's us - won nounId.
				// Remember, using address(this) not contract's owner() here. Both are different.
				return NounStatus.WON;
			} else if (nounOwner == address(0)) {
				// nounId was burned
				// Nouns are burned if nobody bids, or the winner could also burn their noun.
				return NounStatus.BURNED;
			} else {
				if (nounOwner == nounsToken.minter()) {
					// nounId has been freshly minted and is still being auctioned off.
					return NounStatus.MINTED;
				} else {
					// We don't know noun's owner. That means we lost the auction.
					return NounStatus.LOST;
				}
			}
		} catch {
			// ownerOf reverted. that means the nounId does not exist, unless something else happened, like a failed transaction.
			return NounStatus.NOTFOUND;
		}
	}

	/// @notice Returns the number of open claims.
	/// @return Number of open claims.
	function claimsCount(address _address) external view override returns (uint256) {
		return claims[_address].length;
	}

	/// @dev Update nounsAuctionHouse.
	function setNounsAuctionHouseAddress(address _address) external override nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		nounsAuctionHouse = INounsAuctionHouse(_address);
	}

	/// @dev Update the nounsTokenAddress address and nounsToken.
	function setNounsTokenAddress(address _address) external override nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		nounsTokenAddress = _address;
		nounsToken = INounsToken(_address);
	}

	/// @dev Update the fracVaultFactoryAddress address and fracVaultFactory.
	function setFracVaultFactoryAddress(address _address) external override nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		fracVaultFactoryAddress = _address;
		fracVaultFactory = IFracVaultFactory(_address);
	}

	/// @dev Update the nounsPartyCuratorAddress address.
	function setNounsPartyCuratorAddress(address _address) external override nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		nounsPartyCuratorAddress = _address;
	}

	/// @dev Update the nounsPartyTreasuryAddress address.
	function setNounsPartyTreasuryAddress(address _address) external override nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		nounsPartyTreasuryAddress = _address;
	}

	/// @dev Update the nouns party fee.
	function setNounsPartyFee(uint256 _fee) external override nonReentrant whenPaused onlyOwner {
		emit LogSetNounsPartyFee(_fee);
		nounsPartyFee = _fee;
	}

	/// @dev Update bid increase. No pause required.
	function setBidIncrease(uint256 _bidIncrease) external override nonReentrant onlyOwner {
		require(_bidIncrease > 0, "Must be > 0");
		emit LogBidIncrease(_bidIncrease);
		bidIncrease = _bidIncrease;
	}

	/// @dev Update nounsAuctionHouse's bid increase. No pause required.
	function setNounsAuctionHouseBidIncrease(uint256 _bidIncrease) external override nonReentrant onlyOwner {
		require(_bidIncrease > 0, "Must be > 0");
		emit LogNounsAuctionHouseBidIncrease(_bidIncrease);
		nounsAuctionHouseBidIncrease = _bidIncrease;
	}

	/// @dev Update allowBid. No pause required.
	function setAllowBid(bool _allow) external override nonReentrant onlyOwner {
		emit LogAllowBid(_allow);
		allowBid = _allow;
	}

	/// @dev Pause the contract, freezing core functionalities to prevent bad things from happening in case of emergency.
	function emergencyPause() external override nonReentrant onlyOwner {
		emit LogEmergencyPause();
		_pause();
	}

	/// @dev Unpause the contract.
	function emergencyUnpause() external override nonReentrant onlyOwner {
		emit LogEmergencyUnpause();
		_unpause();
	}

	/// @dev Authorize OpenZepplin's upgrade function, guarded by onlyOwner.
	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {} // solhint-disable-line no-empty-blocks

	/// @dev Transfer ETH and revert if unsuccessful. Only forward 30,000 gas to the callee.
	function _transferETH(address _to, uint256 _value) private {
		(bool success, ) = _to.call{ value: _value, gas: 30_000 }(new bytes(0)); // solhint-disable-line avoid-low-level-calls
		require(success, "Transfer failed");
	}

	/// @dev Allow contract to receive Eth. For example when we are outbid.
	receive() external payable {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFracTokenVault {
	function updateCurator(address curator) external;

	function transfer(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IFracVaultFactory {
	function vaults(uint256) external returns (address);

	function mint(
		string memory name,
		string memory symbol,
		address token,
		uint256 id,
		uint256 supply,
		uint256 listPrice,
		uint256 fee
	) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface INounsAuctionHouse {
	struct Auction {
		uint256 nounId;
		uint256 amount;
		uint256 startTime;
		uint256 endTime;
		address payable bidder;
		bool settled;
	}

	function createBid(uint256 nounId) external payable;

	function auction()
		external
		view
		returns (
			uint256, // nounId
			uint256, // amount
			uint256, // startTime
			uint256, // endTime
			address payable, // bidder
			bool // settled
		);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface INounsParty {
	struct Deposit {
		address owner;
		uint256 amount;
	}

	struct TokenClaim {
		uint256 nounId;
		uint256 tokens;
	}

	enum NounStatus {
		WON,
		BURNED,
		MINTED,
		LOST,
		NOTFOUND
	}

	event LogWithdraw(address sender, uint256 amount);

	event LogFractionalize(uint256 indexed nounId, uint256 supply, uint256 fee);

	event LogClaim(address sender, uint256 nounId, address fracTokenVaultAddress, uint256 tokens);

	event LogSettleWon(uint256 nounId);

	event LogSettleLost(uint256 nounId);

	event LogDeposit(address sender, uint256 amount);

	event LogBid(uint256 indexed nounId, uint256 amount, address sender);

	event LogSetNounsPartyFee(uint256 fee);

	event LogBidIncrease(uint256 bidIncrease);

	event LogAllowBid(bool allow);

	event LogNounsAuctionHouseBidIncrease(uint256 bidIncrease);

	event LogEmergencyUpdatePendingSettled(uint256 nounId, uint256 pendingSettledCount);

	event LogEmergencyPause();

	event LogEmergencyUnpause();

	function deposit() external payable;

	function bid() external payable;

	function settle() external;

	function settleNext() external view returns (uint256 nounId);

	function claim() external;

	function withdraw() external payable;

	function deposits() external view returns (Deposit[] memory);

	function claimsCount(address _address) external view returns (uint256);

	function auctionIsHot() external view returns (bool);

	function maxBid() external view returns (uint256, uint256);

	function setNounsAuctionHouseAddress(address newAddress) external;

	function setNounsTokenAddress(address newAddress) external;

	function setFracVaultFactoryAddress(address newAddress) external;

	function setNounsPartyCuratorAddress(address newAddress) external;

	function setNounsPartyTreasuryAddress(address newAddress) external;

	function setNounsPartyFee(uint256 fee) external;

	function setBidIncrease(uint256 bidIncrease) external;

	function setAllowBid(bool allow) external;

	function setNounsAuctionHouseBidIncrease(uint256 bidIncrease) external;

	function emergencyPause() external;

	function emergencyUnpause() external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

interface INounsToken is IERC721Upgradeable {
	function minter() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}