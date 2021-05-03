// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IVybeDAO.sol";
import "./IVybeStake.sol";
import "./MicroERC20.sol";
import "./ILaunchpad.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router01.sol";

contract Launchpad is ReentrancyGuard, Ownable, ILaunchpad {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Proposal {
        // Stakers who voted yes
        mapping(address => bool) stakers;
        // token to sell
        address token;
        // quantity to sell
        uint256 quantity;
        // minimum price to sell for
        uint256 price;
        // Whether or not the proposal is completed
        // Stops it from being acted on multiple times
        bool completed;
    }

    mapping(uint64 => Proposal) public proposals;
    mapping(uint64 => mapping(address => bool)) public used;

    // ID to use for the next proposal
    uint64 _nextProposalID;
    IVybeStake private _stake;
    IERC20 private _VYBE;

    uint256 public constant CREATOR_SPLIT = 25;
    uint256 public constant LIQUIDITY_SPLIT = 10;
    uint256 public constant DEV_SPLIT = 2;

    address public _devFund;
    IUniswapV2Router01 public _router;
    address public _DAO;

    // Check the proposal is valid
    modifier pendingProposal(uint64 proposal) {
        require(!proposals[proposal].completed);
        _;
    }

    constructor(address DAO, address devFund, address router) Ownable(msg.sender) public {
        _DAO = DAO;
        _stake = IVybeStake(IVybeDAO(_DAO).stake());
        _VYBE = IERC20(_stake.vybe());

        _devFund = devFund;
        emit DevFundChanged(address(0), devFund);

        _router = IUniswapV2Router01(router);
        _VYBE.approve(address(_router), uint256(-1));
    }

    function transferDevFund(address newDevFund) external override {
      require(msg.sender == _devFund);
      emit DevFundChanged(_devFund, newDevFund);
      _devFund = newDevFund;
    }

    // transfer ownership to the next DAO
    function transferOwnership(address newDAO) onlyOwner() public override {
      _DAO = newDAO;
      Ownable.transferOwnership(_DAO);
    }

    function deploy(string memory symbol, string memory name, uint256 vybePerWholeToken) external override returns (address) {
      MicroERC20 token = new MicroERC20(name, symbol);
      // the usage of SafeMath here is unnecessary
      // it is minimal gas though and safe
      // allows adjusting token supply in the future without side effects
      uint256 percent = token.totalSupply().div(100);

      // send 25% to the creator
      token.transfer(msg.sender, CREATOR_SPLIT.mul(percent));

      // put up 10% in liquidity against VYBE
      uint256 tenPercent = LIQUIDITY_SPLIT.mul(percent);
      uint256 vybeValue = tenPercent.div(1e18).mul(vybePerWholeToken);

      // transfer the needed VYBE to self
      _VYBE.safeTransferFrom(msg.sender, address(this), vybeValue);

      // approve the router to spend the new token
      token.approve(address(_router), uint256(-1));
      // since we're creating the pair, the minimum amount acceptable is the desired amount
      // this is because we should decide the ratio right now as the ones adding the initial liquidity
      // burns the provided liquidity to forever lock it in
      // sets a deadline of this block since this will execute this block
      _router.addLiquidity(address(_VYBE), address(token), vybeValue, tenPercent,
                            vybeValue, tenPercent, address(0), block.timestamp);

      // 2% devfee
      if (_devFund != address(0)) {
        token.transfer(_devFund, DEV_SPLIT.mul(percent));
      }

      // the remaining 63% (or 65% if the dev fund was set to 0) sits here in the DAO for VYBE holders to vote on

      emit TokenDeployed(symbol, name, address(token));
    }

    function proposeSell(address token, uint256 quantity, uint256 price)
        external
        override
        returns (uint64)
    {
        // Increment the next proposal ID now
        // Means we don't have to return a value we subtract one from later
        _nextProposalID += 1;
        emit NewProposal(_nextProposalID);

        // Set up the proposal's metadata
        Proposal storage proposal = proposals[_nextProposalID];
        // Automatically vote for the proposal's creator
        proposal.stakers[msg.sender] = true;

        // set the actual sell info
        proposal.token = token;
        proposal.quantity = quantity;
        proposal.price == price;


        // emit events
        emit SellProposed(_nextProposalID, token, quantity, price);
        emit ProposalVoteAdded(_nextProposalID, msg.sender);

        return _nextProposalID;
    }

    function addVote(uint64 proposalID) external override pendingProposal(proposalID) {
        proposals[proposalID].stakers[msg.sender] = true;
        emit ProposalVoteAdded(proposalID, msg.sender);
    }

    function removeVote(uint64 proposalID) external override pendingProposal(proposalID) {
        proposals[proposalID].stakers[msg.sender] = false;
        emit ProposalVoteRemoved(proposalID, msg.sender);
    }

    // Complete a proposal
    // Takes in a list of stakers so this contract doesn't have to track them all in an array
    // This would be extremely expensive as a stakers vote weight can drop to 0
    // This selective process allows only counting meaningful votes
    function completeProposal(uint64 proposalID, address[] calldata stakers)
        external
        override
        pendingProposal(proposalID)
        nonReentrant
    {
        Proposal storage proposal = proposals[proposalID];

        uint256 requirement = _stake.totalStaked().div(2).add(1);
        // Make sure there's enough vote weight behind this proposal
        uint256 votes = 0;
        for (uint256 i = 0; i < stakers.length; i++) {
            // Don't allow people to vote with flash loans
            if (_stake.lastClaim(stakers[i]) == block.timestamp) {
                continue;
            }
            require(proposal.stakers[stakers[i]]);
            require(!used[proposalID][stakers[i]]);
            used[proposalID][stakers[i]] = true;
            votes = votes.add(_stake.staked(stakers[i]));
        }
        require(votes >= requirement);
        proposal.completed = true;
        emit ProposalPassed(proposalID);

        // uses a direct route as 10% of the supply is in the VYBE liquidity pool
        // actually calculating the route in Solidity would be infeasible and for this to be wrong...
        address[] memory path = new address[](2);
        path[0] = proposal.token;
        path[1] = address(_VYBE);

        _router.swapExactTokensForTokens(
            proposal.quantity,
            proposal.price,
            path,
            // transfer the VYBE to the DAO
            _DAO,
            // don't allow executing in a future block, as that'd be impossible
            block.timestamp
        );
    }
}