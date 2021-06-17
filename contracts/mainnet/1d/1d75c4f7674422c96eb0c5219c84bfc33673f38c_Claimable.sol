/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Claimable Protocol
 * @dev Smart contract allow recipients to claim ERC20 tokens
 *      according to an initial cliff and a vesting period
 *      Formual:
 *      - claimable at cliff: (cliff / vesting) * amount
 *      - claimable at time t after cliff (t0 = start time)
 *        (t - t0) / vesting * amount
 *      - multiple claims, last claim at t1, claim at t:
 *        (t - t1) / vesting * amount
 *        or
 *        (t - t0) / vesting * amount - claimed
 */
contract Claimable is Context {
    using SafeMath for uint256;

    /// @notice unique claim ticket id, auto-increment
    uint256 public currentId;

    /// @notice claim ticket
    /// @dev payable is not needed for ERC20, need more work to support Ether
    struct Ticket {
      address token; // ERC20 token address
      address payable grantor; // grantor address
      address payable beneficiary;
      uint256 cliff; // cliff time from creation in days
      uint256 vesting; // vesting period in days
      uint256 amount; // initial funding amount
      uint256 claimed; // amount already claimed
      uint256 balance; // current balance
      uint256 createdAt; // begin time
      uint256 lastClaimedAt;
      uint256 numClaims;
      bool irrevocable; // cannot be revoked
      bool isRevoked; // return balance to grantor
      uint256 revokedAt; // revoke timestamp
    //   mapping (uint256
    //     => mapping (uint256 => uint256)) claims; // claimId => lastClaimAt => amount
    }

    /// @dev address => id[]
    /// @dev this is expensive but make it easy to create management UI
    mapping (address => uint256[]) private grantorTickets;
    mapping (address => uint256[]) private beneficiaryTickets;

    /**
     * Claim tickets
     */
    /// @notice id => Ticket
    mapping (uint256 => Ticket) public tickets;

    event TicketCreated(uint256 id, address token, uint256 amount, bool irrevocable);
    event Claimed(uint256 id, address token, uint256 amount);
    event Revoked(uint256 id, uint256 amount);

    modifier canView(uint256 _id) {
        Ticket memory ticket = tickets[_id];
        require(ticket.grantor == _msgSender() || ticket.beneficiary == _msgSender(), "Only grantor or beneficiary can view.");
        _;
    }

    modifier notRevoked(uint256 _id) {
        Ticket memory ticket = tickets[_id];
        require(ticket.isRevoked == false, "Ticket is already revoked");
        _;
    }

    /// @dev show all my grantor tickets
    function myGrantorTickets() public view returns (uint256[] memory myTickets) {
        myTickets = grantorTickets[_msgSender()];
    }

    /// @dev show all my beneficiary tickets
    function myBeneficiaryTickets() public view returns (uint256[] memory myTickets) {
        myTickets = beneficiaryTickets[_msgSender()];
    }

    /// @notice special cases: cliff = period: all claimable after the cliff
    function create(address _token, address payable _beneficiary, uint256 _cliff, uint256 _vesting, uint256 _amount, bool _irrevocable) public returns (uint256 ticketId) {
      /// @dev sender needs to approve this contract to fund the claim
      require(_beneficiary != address(0), "Beneficiary is required");
      require(_amount > 0, "Amount is required");
      require(_vesting >= _cliff, "Vesting period should be equal or longer to the cliff");
      ERC20 token = ERC20(_token);
      require(token.balanceOf(_msgSender()) >= _amount, "Insufficient balance");
      require(token.transferFrom(_msgSender(), address(this), _amount), "Funding failed.");
      ticketId = ++currentId;
      Ticket storage ticket = tickets[ticketId];
      ticket.token = _token;
      ticket.grantor = _msgSender();
      ticket.beneficiary = _beneficiary;
      ticket.cliff = _cliff;
      ticket.vesting = _vesting;
      ticket.amount = _amount;
      ticket.balance = _amount;
      ticket.createdAt = block.timestamp;
      ticket.irrevocable = _irrevocable;
      grantorTickets[_msgSender()].push(ticketId);
      beneficiaryTickets[_beneficiary].push(ticketId);
      emit TicketCreated(ticketId, _token, _amount, _irrevocable);
    }

    /// @notice claim available balance, only beneficiary can call
    function claim(uint256 _id) notRevoked(_id) public returns (bool success) {
      Ticket storage ticket = tickets[_id];
      require(ticket.beneficiary == _msgSender(), "Only beneficiary can claim.");
      require(ticket.balance > 0, "Ticket has no balance.");
      ERC20 token = ERC20(ticket.token);
      uint256 amount = available(_id);
      require(amount > 0, "Nothing to claim.");
      require(token.transfer(_msgSender(), amount), "Claim failed");
      ticket.claimed = SafeMath.add(ticket.claimed, amount);
      ticket.balance = SafeMath.sub(ticket.balance, amount);
      ticket.lastClaimedAt = block.timestamp;
      ticket.numClaims = SafeMath.add(ticket.numClaims, 1);
      emit Claimed(_id, ticket.token, amount);
      success = true;
    }

    /// @notice revoke ticket, balance returns to grantor, only grantor can call
    function revoke(uint256 _id) notRevoked(_id) public returns (bool success) {
      Ticket storage ticket = tickets[_id];
      require(ticket.grantor == _msgSender(), "Only grantor can revoke.");
      require(ticket.irrevocable == false, "Ticket is irrevocable.");
      require(ticket.balance > 0, "Ticket has no balance.");
      ERC20 token = ERC20(ticket.token);
      require(token.transfer(_msgSender(), ticket.balance), "Return balance failed");
      ticket.isRevoked = true;
      ticket.balance = 0;
      emit Revoked(_id, ticket.balance);
      success = true;
    }


    /// @dev checks the ticket has cliffed or not
    function hasCliffed(uint256 _id) canView(_id) public view returns (bool) {
        Ticket memory ticket = tickets[_id];
        if (ticket.cliff == 0) {
            return true;
        }
        return block.timestamp > SafeMath.add(ticket.createdAt, SafeMath.mul(ticket.cliff, 86400)); // in seconds 24 x 60 x 60
    }

    /// @dev calculates the available balances excluding cliff and claims
    function unlocked(uint256 _id) canView(_id) public view returns (uint256 amount) {
        Ticket memory ticket = tickets[_id];
        uint256 timeLapsed = SafeMath.sub(block.timestamp, ticket.createdAt); // in seconds
        uint256 vestingInSeconds = SafeMath.mul(ticket.vesting, 86400); // in seconds: 24 x 60 x 60
        amount = SafeMath.div(
            SafeMath.mul(timeLapsed, ticket.amount),
            vestingInSeconds
        );
    }

    /// @notice check available claims, only grantor or beneficiary can call
    function available(uint256 _id) canView(_id) notRevoked(_id) public view returns (uint256 amount) {
        Ticket memory ticket = tickets[_id];
        require(ticket.balance > 0, "Ticket has no balance.");
        if (hasCliffed(_id)) {
            amount = SafeMath.sub(unlocked(_id), ticket.claimed);
        } else {
            amount = 0;
        }
    }
}