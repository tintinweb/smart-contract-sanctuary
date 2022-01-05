//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWETH.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";

import "./Settings.sol";

import "./ERC721HolderUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract TokenVault is ERC20Upgradeable, ERC721HolderUpgradeable {
    using Address for address;

    /// -----------------------------------
    /// -------- BASIC INFORMATION --------
    /// -----------------------------------

    /// @notice weth address
    address public constant weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    /// -----------------------------------
    /// -------- TOKEN INFORMATION --------
    /// -----------------------------------

    /// @notice the ERC721 token address of the vault's token
    address public token;

    /// @notice the ERC721 token ID of the vault's token
    uint256 public id;

    /// -------------------------------------
    /// -------- AUCTION INFORMATION --------
    /// -------------------------------------

    /// @notice the unix timestamp end time of the token auction
    uint256 public auctionEnd;

    /// @notice the length of auctions
    uint256 public auctionLength;

    /// @notice reservePrice * votingTokens
    uint256 public reserveTotal;

    /// @notice the current price of the token during an auction
    uint256 public livePrice;

    /// @notice the current user winning the token auction
    address payable public winning;

    enum State { inactive, live, ended, redeemed }

    State public auctionState;

    /// -----------------------------------
    /// -------- VAULT INFORMATION --------
    /// -----------------------------------

    /// @notice the governance contract which gets paid in ETH
    address public immutable settings;

    /// @notice the address who initially deposited the NFT
    address public curator;

    /// @notice the AUM fee paid to the curator yearly. 3 decimals. ie. 100 = 10%
    uint256 public fee;

    /// @notice the last timestamp where fees were claimed
    uint256 public lastClaimed;

    /// @notice a boolean to indicate if the vault has closed
    bool public vaultClosed;

    /// @notice the number of ownership tokens voting on the reserve price at any given time
    uint256 public votingTokens;

    /// @notice a mapping of users to their desired token price
    mapping(address => uint256) public userPrices;

    /// ------------------------
    /// -------- EVENTS --------
    /// ------------------------

    /// @notice An event emitted when a user updates their price
    event PriceUpdate(address indexed user, uint price);

    /// @notice An event emitted when an auction starts
    event Start(address indexed buyer, uint price);

    /// @notice An event emitted when a bid is made
    event Bid(address indexed buyer, uint price);

    /// @notice An event emitted when an auction is won
    event Won(address indexed buyer, uint price);

    /// @notice An event emitted when someone redeems all tokens for the NFT
    event Redeem(address indexed redeemer);

    /// @notice An event emitted when someone cashes in ERC20 tokens for ETH from an ERC721 token sale
    event Cash(address indexed owner, uint256 shares);

    constructor(address _settings) {
        settings = _settings;
    }

    function initialize(address _curator, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee, string memory _name, string memory _symbol) external initializer {
        // initialize inherited contracts
        __ERC20_init(_name, _symbol);
        __ERC721Holder_init();
        // set storage variables
        token = _token;
        id = _id;
        reserveTotal = _listPrice * _supply;
        auctionLength = 7 days;
        curator = _curator;
        fee = _fee;
        lastClaimed = block.timestamp;
        votingTokens = _listPrice == 0 ? 0 : _supply;

        auctionState = State.inactive;

        _mint(_curator, _supply);
        userPrices[_curator] = _listPrice;
    }

    /// --------------------------------
    /// -------- VIEW FUNCTIONS --------
    /// --------------------------------

    function reservePrice() public view returns(uint256) {
        return votingTokens == 0 ? 0 : reserveTotal / votingTokens;
    }

    /// -------------------------------
    /// -------- GOV FUNCTIONS --------
    /// -------------------------------

    /// @notice allow governance to boot a bad actor curator
    /// @param _curator the new curator
    function kickCurator(address _curator) external {
        require(msg.sender == Ownable(settings).owner(), "kick:not gov");

        curator = _curator;
    }

    /// @notice allow governance to remove bad reserve prices
    function removeReserve(address _user) external {
        require(msg.sender == Ownable(settings).owner(), "remove:not gov");
        require(auctionState == State.inactive, "update:auction live cannot update price");

        uint256 old = userPrices[_user];
        require(0 != old, "update:not an update");
        uint256 weight = balanceOf(_user);

        votingTokens -= weight;
        reserveTotal -= weight * old;
        
        userPrices[_user] = 0;

        emit PriceUpdate(_user, 0);
    }

    /// -----------------------------------
    /// -------- CURATOR FUNCTIONS --------
    /// -----------------------------------

    /// @notice allow curator to update the curator address
    /// @param _curator the new curator
    function updateCurator(address _curator) external {
        require(msg.sender == curator, "update:not curator");

        curator = _curator;
    }

    /// @notice allow curator to update the auction length
    /// @param _length the new base price
    function updateAuctionLength(uint256 _length) external {
        require(msg.sender == curator, "update:not curator");
        require(_length >= ISettings(settings).minAuctionLength() && _length <= ISettings(settings).maxAuctionLength(), "update:invalid auction length");

        auctionLength = _length;
    }

    /// @notice allow the curator to change their fee
    /// @param _fee the new fee
    function updateFee(uint256 _fee) external {
        require(msg.sender == curator, "update:not curator");
        require(_fee <= ISettings(settings).maxCuratorFee(), "update:cannot increase fee this high");

        _claimFees();

        fee = _fee;
    }

    /// @notice external function to claim fees for the curator and governance
    function claimFees() external {
        _claimFees();
    }

    /// @dev interal fuction to calculate and mint fees
    function _claimFees() internal {
        require(auctionState != State.ended, "claim:cannot claim after auction ends");

        // get how much in fees the curator would make in a year
        uint256 currentAnnualFee = fee * totalSupply() / 1000; 
        // get how much that is per second;
        uint256 feePerSecond = currentAnnualFee / 31536000;
        // get how many seconds they are eligible to claim
        uint256 sinceLastClaim = block.timestamp - lastClaimed;
        // get the amount of tokens to mint
        uint256 curatorMint = sinceLastClaim * feePerSecond;

        // now lets do the same for governance
        address govAddress = ISettings(settings).feeReceiver();
        uint256 govFee = ISettings(settings).governanceFee();
        currentAnnualFee = govFee * totalSupply() / 1000; 
        feePerSecond = currentAnnualFee / 31536000;
        uint256 govMint = sinceLastClaim * feePerSecond;

        lastClaimed = block.timestamp;

        _mint(curator, curatorMint);
        _mint(govAddress, govMint);
    }

    /// --------------------------------
    /// -------- CORE FUNCTIONS --------
    /// --------------------------------

    /// @notice a function for an end user to update their desired sale price
    /// @param _new the desired price in ETH
    function updateUserPrice(uint256 _new) external {
        require(auctionState == State.inactive, "update:auction live cannot update price");
        uint256 old = userPrices[msg.sender];
        require(_new != old, "update:not an update");
        uint256 weight = balanceOf(msg.sender);

        if (votingTokens == 0) {
            votingTokens = weight;
            reserveTotal = weight * _new;
        }
        // they are the only one voting
        else if (weight == votingTokens && old != 0) {
            reserveTotal = weight * _new;
        }
        // previously they were not voting
        else if (old == 0) {
            uint256 averageReserve = reserveTotal / votingTokens;

            uint256 reservePriceMin = averageReserve * ISettings(settings).minReserveFactor() / 1000;
            require(_new >= reservePriceMin, "update:reserve price too low");
            uint256 reservePriceMax = averageReserve * ISettings(settings).maxReserveFactor() / 1000;
            require(_new <= reservePriceMax, "update:reserve price too high");

            votingTokens += weight;
            reserveTotal += weight * _new;
        } 
        // they no longer want to vote
        else if (_new == 0) {
            votingTokens -= weight;
            reserveTotal -= weight * old;
        } 
        // they are updating their vote
        else {
            uint256 averageReserve = (reserveTotal - (old * weight)) / (votingTokens - weight);

            uint256 reservePriceMin = averageReserve * ISettings(settings).minReserveFactor() / 1000;
            require(_new >= reservePriceMin, "update:reserve price too low");
            uint256 reservePriceMax = averageReserve * ISettings(settings).maxReserveFactor() / 1000;
            require(_new <= reservePriceMax, "update:reserve price too high");

            reserveTotal = reserveTotal + (weight * _new) - (weight * old);
        }

        userPrices[msg.sender] = _new;

        emit PriceUpdate(msg.sender, _new);
    }

    /// @notice an internal function used to update sender and receivers price on token transfer
    /// @param _from the ERC20 token sender
    /// @param _to the ERC20 token receiver
    /// @param _amount the ERC20 token amount
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if (_from != address(0) && auctionState == State.inactive) {
            uint256 fromPrice = userPrices[_from];
            uint256 toPrice = userPrices[_to];

            // only do something if users have different reserve price
            if (toPrice != fromPrice) {
                // new holder is not a voter
                if (toPrice == 0) {
                    // get the average reserve price ignoring the senders amount
                    votingTokens -= _amount;
                    reserveTotal -= _amount * fromPrice;
                }
                // old holder is not a voter
                else if (fromPrice == 0) {
                    votingTokens += _amount;
                    reserveTotal += _amount * toPrice;
                }
                // both holders are voters
                else {
                    reserveTotal = reserveTotal + (_amount * toPrice) - (_amount * fromPrice);
                }
            }
        }
    }

    /// @notice kick off an auction. Must send reservePrice in ETH
    function start() external payable {
        require(auctionState == State.inactive, "start:no auction starts");
        require(msg.value >= reservePrice(), "start:too low bid");
        require(votingTokens * 1000 >= ISettings(settings).minVotePercentage() * totalSupply(), "start:not enough voters");
        
        auctionEnd = block.timestamp + auctionLength;
        auctionState = State.live;

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Start(msg.sender, msg.value);
    }

    /// @notice an external function to bid on purchasing the vaults NFT. The msg.value is the bid amount
    function bid() external payable {
        require(auctionState == State.live, "bid:auction is not live");
        uint256 increase = ISettings(settings).minBidIncrease() + 1000;
        require(msg.value * 1000 >= livePrice * increase, "bid:too low bid");
        require(block.timestamp < auctionEnd, "bid:auction ended");

        // If bid is within 15 minutes of auction end, extend auction
        if (auctionEnd - block.timestamp <= 15 minutes) {
            auctionEnd += 15 minutes;
        }

        _sendWETH(winning, livePrice);

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Bid(msg.sender, msg.value);
    }

    /// @notice an external function to end an auction after the timer has run out
    function end() external {
        require(auctionState == State.live, "end:vault has already closed");
        require(block.timestamp >= auctionEnd, "end:auction live");

        _claimFees();

        // transfer erc721 to winner
        IERC721(token).transferFrom(address(this), winning, id);

        auctionState = State.ended;

        emit Won(winning, livePrice);
    }

    /// @notice an external function to burn all ERC20 tokens to receive the ERC721 token
    function redeem() external {
        require(auctionState == State.inactive, "redeem:no redeeming");
        _burn(msg.sender, totalSupply());
        
        // transfer erc721 to redeemer
        IERC721(token).transferFrom(address(this), msg.sender, id);
        
        auctionState = State.redeemed;

        emit Redeem(msg.sender);
    }

    /// @notice an external function to burn ERC20 tokens to receive ETH from ERC721 token purchase
    function cash() external {
        require(auctionState == State.ended, "cash:vault not closed yet");
        uint256 bal = balanceOf(msg.sender);
        require(bal > 0, "cash:no tokens to cash out");
        uint256 share = bal * address(this).balance / totalSupply();
        _burn(msg.sender, bal);

        _sendETHOrWETH(payable(msg.sender), share);

        emit Cash(msg.sender, share);
    }

    /// @dev internal helper function to send ETH and WETH on failure
    function _sendWETH(address who, uint256 amount) internal {
        IWETH(weth).deposit{value: amount}();
        IWETH(weth).transfer(who, IWETH(weth).balanceOf(address(this)));
    }

    /// @dev internal helper function to send ETH and WETH on failure
    function _sendETHOrWETH(address who, uint256 amount) internal {
        // contracts get bet WETH because they can be mean
        if (who.isContract()) {
            IWETH(weth).deposit{value: amount}();
            IWETH(weth).transfer(who, IWETH(weth).balanceOf(address(this)));
        } else {
            payable(who).transfer(amount);
        }
    }

}