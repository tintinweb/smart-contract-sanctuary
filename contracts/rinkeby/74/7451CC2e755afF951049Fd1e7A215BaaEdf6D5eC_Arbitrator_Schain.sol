// contracts/Arbitrator_Schain.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/utils/Address.sol';
import "./utils/Context.sol";
import "./utils/MinterRole.sol";

contract Arbitrator_Schain is Context, MinterRole {
    using Address for address payable;
    address payable private owner;

    uint256 yeeCount;
    uint256 nayCount;

    mapping(address => uint) public balances;

    event Deposit(address sender, uint amount);
    event Withdrawal(address receiver, uint amount);
    event Transfer(address sender, address receiver, uint amount);
    event DisputeOpened(uint256 disputeNumber);
    event VoteCast(uint256 disputeNumber, address voter);

    struct Dispute {
        // the person opening the dispute
        address prosecutor;
        // the defendant of the dispute
        address defendant;
        // the amount in $$ that the prosecutor is requesting in damages
        uint256 amount;
        // response to dispute
        uint256 response;
        // file hash (stored on ipfs) on prosecutor evidence related to the case
        bytes32 prosecutorEvidence;
        // file hash (stored on ipfs) on defendant evidence related to the case
        bytes32 defendantEvidence;
        // status of the current dispute
        disputeStatus status;
        // status of the current dispute
        disputeRulings ruling;
        // addresses of users that voted
        mapping(address => bool) voters;
        // mapping from address of voters to yes or no
        mapping(address => bool) votedYesOrNo;
        // mapping from voters to hashed vote
        mapping(address => uint256)  votedYesOrNoSecret;
        // number of users that voted yes
        uint yeeCount;
        // number of users that voted no
        uint nayCount;
        // date dispute was opened
        uint256 openDate;
        // deadline to vote
        uint256 voteDeadline;
        // date dispute was closed
        uint256 closeDate;
    }
    Dispute[] public disputes;
    uint public totalSupply = 0; // 0 dispute tokens

    enum disputeStatus {PENDING, CLOSED, VOTING} // to do: APPEAL
    enum disputeRulings {PENDING, NOCONTEST, GUILTY, INNOCENT}

    constructor() public {
        owner = msg.sender;
        }
    
    // file a new dispute
    function openDispute(uint256 _compensationRequested, bytes32 _disputeSummary, address _defendant) 
    public returns(uint256 disputeNumber) {
        // set date info
        uint256 today = 0;
        uint256 deadline = today + 3;
        // create new dispute
        Dispute memory d;
        // set parties
        d.prosecutor = msg.sender;
        d.defendant = _defendant;
        // add prosecutor's information
        d.amount = _compensationRequested;
        d.prosecutorEvidence = _disputeSummary;
        // set status and voting details
        d.status = disputeStatus.PENDING;
        d.ruling = disputeRulings.PENDING;
        d.yeeCount = 0;
        d.nayCount = 0;
        d.openDate = today;
        d.voteDeadline = deadline;
        // add dispute to list of disputes
        disputes.push(d);
        // output this dispute's number for reference
        disputeNumber = disputes.length - 1;
        emit DisputeOpened(disputeNumber);
        return disputeNumber;
    }

    // respond to dispute
    // to do: _counterSummary & _comp optional
    function respondToDispute(uint256 disputeNumber, uint256 _response, bytes32 _counterSummary, uint256 _comp)
    public payable primaryParties(disputeNumber) {
        disputes[disputeNumber].response = _response;
        if (_response==0 || _response==1) { // plea: 0 = no contest, 1 = guilty
            settleDispute(disputeNumber, _response);
        }
        else if (_response==2) { // plea: counter
            counterDispute(disputeNumber, _counterSummary, _comp);
        }
        // start vote
        else { // plea: innocent / otherwise
            disputes[disputeNumber].status = disputeStatus.VOTING;
        }
    }

    // settle dispute
    function settleDispute(uint256 disputeNumber, uint256 _response) public payable primaryParties(disputeNumber) {
        // deposit & transfer funds
        deposit();
        transfer(disputes[disputeNumber].prosecutor, disputes[disputeNumber].amount);
        // no contest or guilty ruling
        if (_response==0) {
            disputes[disputeNumber].ruling = disputeRulings.NOCONTEST;
        }
        else {
            disputes[disputeNumber].ruling = disputeRulings.GUILTY;
        }
        // close dispute
        disputes[disputeNumber].status = disputeStatus.CLOSED;
    }

    // counter dispute
    function counterDispute(uint256 disputeNumber, bytes32 _counterSummary, uint256 _comp) public payable primaryParties(disputeNumber) {
        // defense
        disputes[disputeNumber].defendantEvidence = _counterSummary;
        disputes[disputeNumber].amount = _comp;
        // were funds deposited?
        if (msg.value>0) {
            deposit();
            // to do: logic if accepted, if not
        }
    }

    // deposit funds
    // in eth (to do: make match with everything else)
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
    }

    // withdraw funds
    // in wei (limited to int values)
    function withdraw(uint256 weiAmount) public {
        require(balances[msg.sender] >= weiAmount, "Insufficient funds");
        // send funds to requester
        msg.sender.sendValue(weiAmount);
        // adjust balance & tag event
        balances[msg.sender] -= weiAmount;
        emit Withdrawal(msg.sender, weiAmount);
    }

    // transfer funds
    // in wei (limited to int values)
    function transfer(address receiver, uint256 weiAmount) public {
        require(balances[msg.sender] >= weiAmount, "Insufficient funds");
        emit Transfer(msg.sender, receiver, weiAmount);
        balances[msg.sender] -= weiAmount;
        balances[receiver] += weiAmount;
    }

    // vote yee 1 or nay 0
    function vote(uint256 disputeNumber, bool voteCast) public {
        require(disputes[disputeNumber].status==disputeStatus.VOTING, "voting not live :)");
        require(!disputes[disputeNumber].voters[msg.sender], "already voted :)");
        // if voting is live and address hasn't voted yet, count vote  
        if(voteCast) {disputes[disputeNumber].yeeCount++;}
        if(!voteCast) {disputes[disputeNumber].nayCount++;}
        // address has voted, mark them as such
        disputes[disputeNumber].voters[msg.sender] = true;
        emit VoteCast(disputeNumber, msg.sender);
    }

    // outputs current vote counts
    function getVotes(uint256 disputeNumber) public view returns (uint yesVotes, uint noVotes) {
        return(disputes[disputeNumber].yeeCount, disputes[disputeNumber].nayCount);
    }

    // // lets user know if their vote has been counted
    // // status: WIP
    // function haveYouVoted(uint256 disputeNumber) public view returns (bool) {
    //     return disputes[disputeNumber].voters[msg.sender];
    // }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += uint96(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = uint96(accountBalance - amount);
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    // for functions that should only be called by prosecutor or defendant
    modifier primaryParties(uint256 disputeNumber) {
        require((msg.sender == disputes[disputeNumber].prosecutor) || (msg.sender == disputes[disputeNumber].defendant));
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // function _msgData() internal view virtual returns (bytes calldata) { // TypeError: Data location -> calldata
    //     this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    //     return msg.data;
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
import "./Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

