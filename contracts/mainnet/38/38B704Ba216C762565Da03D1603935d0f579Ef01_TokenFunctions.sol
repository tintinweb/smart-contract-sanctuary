/**
 *Submitted for verification at Etherscan.io on 2020-09-18
*/

// File: nexusmutual-contracts/contracts/external/openzeppelin-solidity/token/ERC20/IERC20.sol

pragma solidity 0.5.7;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: nexusmutual-contracts/contracts/external/openzeppelin-solidity/math/SafeMath.sol

pragma solidity 0.5.7;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: nexusmutual-contracts/contracts/NXMToken.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;




contract NXMToken is IERC20 {
    using SafeMath for uint256;

    event WhiteListed(address indexed member);

    event BlackListed(address indexed member);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    mapping (address => bool) public whiteListed;

    mapping(address => uint) public isLockedForMV;

    uint256 private _totalSupply;

    string public name = "NXM";
    string public symbol = "NXM";
    uint8 public decimals = 18;
    address public operator;

    modifier canTransfer(address _to) {
        require(whiteListed[_to]);
        _;
    }

    modifier onlyOperator() {
        if (operator != address(0))
            require(msg.sender == operator);
        _;
    }

    constructor(address _founderAddress, uint _initialSupply) public {
        _mint(_founderAddress, _initialSupply);
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Adds a user to whitelist
    * @param _member address to add to whitelist
    */
    function addToWhiteList(address _member) public onlyOperator returns (bool) {
        whiteListed[_member] = true;
        emit WhiteListed(_member);
        return true;
    }

    /**
    * @dev removes a user from whitelist
    * @param _member address to remove from whitelist
    */
    function removeFromWhiteList(address _member) public onlyOperator returns (bool) {
        whiteListed[_member] = false;
        emit BlackListed(_member);
        return true;
    }

    /**
    * @dev change operator address 
    * @param _newOperator address of new operator
    */
    function changeOperator(address _newOperator) public onlyOperator returns (bool) {
        operator = _newOperator;
        return true;
    }

    /**
    * @dev burns an amount of the tokens of the message sender
    * account.
    * @param amount The amount that will be burnt.
    */
    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    /**
    * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param from address The address which you want to send tokens from
    * @param value uint256 The amount of token to be burned
    */
    function burnFrom(address from, uint256 value) public returns (bool) {
        _burnFrom(from, value);
        return true;
    }

    /**
    * @dev function that mints an amount of the token and assigns it to
    * an account.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function mint(address account, uint256 amount) public onlyOperator {
        _mint(account, amount);
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public canTransfer(to) returns (bool) {

        require(isLockedForMV[msg.sender] < now); // if not voted under governance
        require(value <= _balances[msg.sender]);
        _transfer(to, value); 
        return true;
    }

    /**
    * @dev Transfer tokens to the operator from the specified address
    * @param from The address to transfer from.
    * @param value The amount to be transferred.
    */
    function operatorTransfer(address from, uint256 value) public onlyOperator returns (bool) {
        require(value <= _balances[from]);
        _transferFrom(from, operator, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        canTransfer(to)
        returns (bool)
    {
        require(isLockedForMV[from] < now); // if not voted under governance
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        _transferFrom(from, to, value);
        return true;
    }

    /**
     * @dev Lock the user's tokens 
     * @param _of user's address.
     */
    function lockForMemberVote(address _of, uint _days) public onlyOperator {
        if (_days.add(now) > isLockedForMV[_of])
            isLockedForMV[_of] = _days.add(now);
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address to, uint256 value) internal {
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function _transferFrom(
        address from,
        address to,
        uint256 value
    )
        internal
    {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
    }

    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param amount The amount that will be burnt.
    */
    function _burn(address account, uint256 amount) internal {
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowed[account][msg.sender]);

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        value);
        _burn(account, value);
    }
}

// File: nexusmutual-contracts/contracts/external/govblocks-protocol/interfaces/IProposalCategory.sol

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract IProposalCategory {

    event Category(
        uint indexed categoryId,
        string categoryName,
        string actionHash
    );

    /// @dev Adds new category
    /// @param _name Category name
    /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
    /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    /// @param _contractAddress address of contract to call after proposal is accepted
    /// @param _contractName name of contract to be called after proposal is accepted
    /// @param _incentives rewards to distributed after proposal is accepted
    function addCategory(
        string calldata _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc, 
        uint[] calldata _allowedToCreateProposal,
        uint _closingTime,
        string calldata _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] calldata _incentives
    ) 
        external;

    /// @dev gets category details
    function category(uint _categoryId)
        external
        view
        returns(
            uint categoryId,
            uint memberRoleToVote,
            uint majorityVotePerc,
            uint quorumPerc,
            uint[] memory allowedToCreateProposal,
            uint closingTime,
            uint minStake
        );
    
    ///@dev gets category action details
    function categoryAction(uint _categoryId)
        external
        view
        returns(
            uint categoryId,
            address contractAddress,
            bytes2 contractName,
            uint defaultIncentive
        );
    
    /// @dev Gets Total number of categories added till now
    function totalCategories() external view returns(uint numberOfCategories);

    /// @dev Updates category details
    /// @param _categoryId Category id that needs to be updated
    /// @param _name Category name
    /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
    /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    /// @param _contractAddress address of contract to call after proposal is accepted
    /// @param _contractName name of contract to be called after proposal is accepted
    /// @param _incentives rewards to distributed after proposal is accepted
    function updateCategory(
        uint _categoryId, 
        string memory _name, 
        uint _memberRoleToVote, 
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives
    )
        public;

}

// File: nexusmutual-contracts/contracts/external/govblocks-protocol/Governed.sol

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract IMaster {
    function getLatestAddress(bytes2 _module) public view returns(address);
}


contract Governed {

    address public masterAddress; // Name of the dApp, needs to be set by contracts inheriting this contract

    /// @dev modifier that allows only the authorized addresses to execute the function
    modifier onlyAuthorizedToGovern() {
        IMaster ms = IMaster(masterAddress);
        require(ms.getLatestAddress("GV") == msg.sender, "Not authorized");
        _;
    }

    /// @dev checks if an address is authorized to govern
    function isAuthorizedToGovern(address _toCheck) public view returns(bool) {
        IMaster ms = IMaster(masterAddress);
        return (ms.getLatestAddress("GV") == _toCheck);
    } 

}

// File: nexusmutual-contracts/contracts/INXMMaster.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract INXMMaster {

    address public tokenAddress;

    address public owner;


    uint public pauseTime;

    function delegateCallBack(bytes32 myid) external;

    function masterInitialized() public view returns(bool);
    
    function isInternal(address _add) public view returns(bool);

    function isPause() public view returns(bool check);

    function isOwner(address _add) public view returns(bool);

    function isMember(address _add) public view returns(bool);
    
    function checkIsAuthToGoverned(address _add) public view returns(bool);

    function updatePauseTime(uint _time) public;

    function dAppLocker() public view returns(address _add);

    function dAppToken() public view returns(address _add);

    function getLatestAddress(bytes2 _contractName) public view returns(address payable contractAddress);
}

// File: nexusmutual-contracts/contracts/Iupgradable.sol

pragma solidity 0.5.7;



contract Iupgradable {

    INXMMaster public ms;
    address public nxMasterAddress;

    modifier onlyInternal {
        require(ms.isInternal(msg.sender));
        _;
    }

    modifier isMemberAndcheckPause {
        require(ms.isPause() == false && ms.isMember(msg.sender) == true);
        _;
    }

    modifier onlyOwner {
        require(ms.isOwner(msg.sender));
        _;
    }

    modifier checkPause {
        require(ms.isPause() == false);
        _;
    }

    modifier isMember {
        require(ms.isMember(msg.sender), "Not member");
        _;
    }

    /**
     * @dev Iupgradable Interface to update dependent contract address
     */
    function  changeDependentContractAddress() public;

    /**
     * @dev change master address
     * @param _masterAddress is the new address
     */
    function changeMasterAddress(address _masterAddress) public {
        if (address(ms) != address(0)) {
            require(address(ms) == msg.sender, "Not master");
        }
        ms = INXMMaster(_masterAddress);
        nxMasterAddress = _masterAddress;
    }

}

// File: nexusmutual-contracts/contracts/interfaces/IPooledStaking.sol

pragma solidity ^0.5.7;

interface IPooledStaking {

    function accumulateReward(address contractAddress, uint amount) external;
    function pushBurn(address contractAddress, uint amount) external;
    function hasPendingActions() external view returns (bool);

    function contractStake(address contractAddress) external view returns (uint);
    function stakerReward(address staker) external view returns (uint);
    function stakerDeposit(address staker) external view returns (uint);
    function stakerContractStake(address staker, address contractAddress) external view returns (uint);

    function withdraw(uint amount) external;
    function stakerMaxWithdrawable(address stakerAddress) external view returns (uint);
    function withdrawReward(address stakerAddress) external;
}

// File: nexusmutual-contracts/contracts/TokenFunctions.sol

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;





contract TokenFunctions is Iupgradable {
    using SafeMath for uint;

    MCR internal m1;
    MemberRoles internal mr;
    NXMToken public tk;
    TokenController internal tc;
    TokenData internal td;
    QuotationData internal qd;
    ClaimsReward internal cr;
    Governance internal gv;
    PoolData internal pd;
    IPooledStaking pooledStaking;

    event BurnCATokens(uint claimId, address addr, uint amount);

    /**
     * @dev Rewards stakers on purchase of cover on smart contract.
     * @param _contractAddress smart contract address.
     * @param _coverPriceNXM cover price in NXM.
     */
    function pushStakerRewards(address _contractAddress, uint _coverPriceNXM) external onlyInternal {
        uint rewardValue = _coverPriceNXM.mul(td.stakerCommissionPer()).div(100);
        pooledStaking.accumulateReward(_contractAddress, rewardValue);
    }

    /**
    * @dev Deprecated in favor of burnStakedTokens
    */
    function burnStakerLockedToken(uint, bytes4, uint) external {
        // noop
    }

    /**
    * @dev Burns tokens staked on smart contract covered by coverId. Called when a payout is succesfully executed.
    * @param coverId cover id
    * @param coverCurrency cover currency
    * @param sumAssured amount of $curr to burn
    */
    function burnStakedTokens(uint coverId, bytes4 coverCurrency, uint sumAssured) external onlyInternal {
        (, address scAddress) = qd.getscAddressOfCover(coverId);
        uint tokenPrice = m1.calculateTokenPrice(coverCurrency);
        uint burnNXMAmount = sumAssured.mul(1e18).div(tokenPrice);
        pooledStaking.pushBurn(scAddress, burnNXMAmount);
    }

    /**
     * @dev Gets the total staked NXM tokens against
     * Smart contract by all stakers
     * @param _stakedContractAddress smart contract address.
     * @return amount total staked NXM tokens.
     */
    function deprecated_getTotalStakedTokensOnSmartContract(
        address _stakedContractAddress
    )
        external
        view
        returns(uint)
    {
        uint stakedAmount = 0;
        address stakerAddress;
        uint staketLen = td.getStakedContractStakersLength(_stakedContractAddress);

        for (uint i = 0; i < staketLen; i++) {
            stakerAddress = td.getStakedContractStakerByIndex(_stakedContractAddress, i);
            uint stakerIndex = td.getStakedContractStakerIndex(
                _stakedContractAddress, i);
            uint currentlyStaked;
            (, currentlyStaked) = _deprecated_unlockableBeforeBurningAndCanBurn(stakerAddress,
                _stakedContractAddress, stakerIndex);
            stakedAmount = stakedAmount.add(currentlyStaked);
        }

        return stakedAmount;
    }

    /**
     * @dev Returns amount of NXM Tokens locked as Cover Note for given coverId.
     * @param _of address of the coverHolder.
     * @param _coverId coverId of the cover.
     */
    function getUserLockedCNTokens(address _of, uint _coverId) external view returns(uint) {
        return _getUserLockedCNTokens(_of, _coverId);
    }

    /**
     * @dev to get the all the cover locked tokens of a user
     * @param _of is the user address in concern
     * @return amount locked
     */
    function getUserAllLockedCNTokens(address _of) external view returns(uint amount) {
        for (uint i = 0; i < qd.getUserCoverLength(_of); i++) {
            amount = amount.add(_getUserLockedCNTokens(_of, qd.getAllCoversOfUser(_of)[i]));
        }
    }

    /**
     * @dev Returns amount of NXM Tokens locked as Cover Note against given coverId.
     * @param _coverId coverId of the cover.
     */
    function getLockedCNAgainstCover(uint _coverId) external view returns(uint) {
        return _getLockedCNAgainstCover(_coverId);
    }

    /**
     * @dev Returns total amount of staked NXM Tokens on all smart contracts.
     * @param _stakerAddress address of the Staker.
     */
    function deprecated_getStakerAllLockedTokens(address _stakerAddress) external view returns (uint amount) {
        uint stakedAmount = 0;
        address scAddress;
        uint scIndex;
        for (uint i = 0; i < td.getStakerStakedContractLength(_stakerAddress); i++) {
            scAddress = td.getStakerStakedContractByIndex(_stakerAddress, i);
            scIndex = td.getStakerStakedContractIndex(_stakerAddress, i);
            uint currentlyStaked;
            (, currentlyStaked) = _deprecated_unlockableBeforeBurningAndCanBurn(_stakerAddress, scAddress, i);
            stakedAmount = stakedAmount.add(currentlyStaked);
        }
        amount = stakedAmount;
    }

    /**
     * @dev Returns total unlockable amount of staked NXM Tokens on all smart contract .
     * @param _stakerAddress address of the Staker.
     */
    function deprecated_getStakerAllUnlockableStakedTokens(
        address _stakerAddress
    )
    external
    view
    returns (uint amount)
    {
        uint unlockableAmount = 0;
        address scAddress;
        uint scIndex;
        for (uint i = 0; i < td.getStakerStakedContractLength(_stakerAddress); i++) {
            scAddress = td.getStakerStakedContractByIndex(_stakerAddress, i);
            scIndex = td.getStakerStakedContractIndex(_stakerAddress, i);
            unlockableAmount = unlockableAmount.add(
                _deprecated_getStakerUnlockableTokensOnSmartContract(_stakerAddress, scAddress,
                scIndex));
        }
        amount = unlockableAmount;
    }

    /**
     * @dev Change Dependent Contract Address
     */
    function changeDependentContractAddress() public {
        tk = NXMToken(ms.tokenAddress());
        td = TokenData(ms.getLatestAddress("TD"));
        tc = TokenController(ms.getLatestAddress("TC"));
        cr = ClaimsReward(ms.getLatestAddress("CR"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        m1 = MCR(ms.getLatestAddress("MC"));
        gv = Governance(ms.getLatestAddress("GV"));
        mr = MemberRoles(ms.getLatestAddress("MR"));
        pd = PoolData(ms.getLatestAddress("PD"));
        pooledStaking = IPooledStaking(ms.getLatestAddress("PS"));
    }

    /**
     * @dev Gets the Token price in a given currency
     * @param curr Currency name.
     * @return price Token Price.
     */
    function getTokenPrice(bytes4 curr) public view returns(uint price) {
        price = m1.calculateTokenPrice(curr);
    }

    /**
     * @dev Set the flag to check if cover note is deposited against the cover id
     * @param coverId Cover Id.
     */
    function depositCN(uint coverId) public onlyInternal returns (bool success) {
        require(_getLockedCNAgainstCover(coverId) > 0, "No cover note available");
        td.setDepositCN(coverId, true);
        success = true;
    }

    /**
     * @param _of address of Member
     * @param _coverId Cover Id
     * @param _lockTime Pending Time + Cover Period 7*1 days
     */
    function extendCNEPOff(address _of, uint _coverId, uint _lockTime) public onlyInternal {
        uint timeStamp = now.add(_lockTime);
        uint coverValidUntil = qd.getValidityOfCover(_coverId);
        if (timeStamp >= coverValidUntil) {
            bytes32 reason = keccak256(abi.encodePacked("CN", _of, _coverId));
            tc.extendLockOf(_of, reason, timeStamp);
        }
    }

    /**
     * @dev to burn the deposited cover tokens
     * @param coverId is id of cover whose tokens have to be burned
     * @return the status of the successful burning
     */
    function burnDepositCN(uint coverId) public onlyInternal returns (bool success) {
        address _of = qd.getCoverMemberAddress(coverId);
        uint amount;
        (amount, ) = td.depositedCN(coverId);
        amount = (amount.mul(50)).div(100);
        bytes32 reason = keccak256(abi.encodePacked("CN", _of, coverId));
        tc.burnLockedTokens(_of, reason, amount);
        success = true;
    }

    /**
     * @dev Unlocks covernote locked against a given cover
     * @param coverId id of cover
     */
    function unlockCN(uint coverId) public onlyInternal {
        (, bool isDeposited) = td.depositedCN(coverId);
        require(!isDeposited,"Cover note is deposited and can not be released");
        uint lockedCN = _getLockedCNAgainstCover(coverId);
        if (lockedCN != 0) {
            address coverHolder = qd.getCoverMemberAddress(coverId);
            bytes32 reason = keccak256(abi.encodePacked("CN", coverHolder, coverId));
            tc.releaseLockedTokens(coverHolder, reason, lockedCN);
        }
    }

    /**
     * @dev Burns tokens used for fraudulent voting against a claim
     * @param claimid Claim Id.
     * @param _value number of tokens to be burned
     * @param _of Claim Assessor's address.
     */
    function burnCAToken(uint claimid, uint _value, address _of) public {

        require(ms.checkIsAuthToGoverned(msg.sender));
        tc.burnLockedTokens(_of, "CLA", _value);
        emit BurnCATokens(claimid, _of, _value);
    }

    /**
     * @dev to lock cover note tokens
     * @param coverNoteAmount is number of tokens to be locked
     * @param coverPeriod is cover period in concern
     * @param coverId is the cover id of cover in concern
     * @param _of address whose tokens are to be locked
     */
    function lockCN(
        uint coverNoteAmount,
        uint coverPeriod,
        uint coverId,
        address _of
    )
        public
        onlyInternal
    {
        uint validity = (coverPeriod * 1 days).add(td.lockTokenTimeAfterCoverExp());
        bytes32 reason = keccak256(abi.encodePacked("CN", _of, coverId));
        td.setDepositCNAmount(coverId, coverNoteAmount);
        tc.lockOf(_of, reason, coverNoteAmount, validity);
    }

    /**
     * @dev to check if a  member is locked for member vote
     * @param _of is the member address in concern
     * @return the boolean status
     */
    function isLockedForMemberVote(address _of) public view returns(bool) {
        return now < tk.isLockedForMV(_of);
    }

    /**
     * @dev Internal function to gets amount of locked NXM tokens,
     * staked against smartcontract by index
     * @param _stakerAddress address of user
     * @param _stakedContractAddress staked contract address
     * @param _stakedContractIndex index of staking
     */
    function deprecated_getStakerLockedTokensOnSmartContract (
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        public
        view
        returns
        (uint amount)
    {
        amount = _deprecated_getStakerLockedTokensOnSmartContract(_stakerAddress,
            _stakedContractAddress, _stakedContractIndex);
    }

    /**
     * @dev Function to gets unlockable amount of locked NXM
     * tokens, staked against smartcontract by index
     * @param stakerAddress address of staker
     * @param stakedContractAddress staked contract address
     * @param stakerIndex index of staking
     */
    function deprecated_getStakerUnlockableTokensOnSmartContract (
        address stakerAddress,
        address stakedContractAddress,
        uint stakerIndex
    )
        public
        view
        returns (uint)
    {
        return _deprecated_getStakerUnlockableTokensOnSmartContract(stakerAddress, stakedContractAddress,
        td.getStakerStakedContractIndex(stakerAddress, stakerIndex));
    }

    /**
     * @dev releases unlockable staked tokens to staker
     */
    function deprecated_unlockStakerUnlockableTokens(address _stakerAddress) public checkPause {
        uint unlockableAmount;
        address scAddress;
        bytes32 reason;
        uint scIndex;
        for (uint i = 0; i < td.getStakerStakedContractLength(_stakerAddress); i++) {
            scAddress = td.getStakerStakedContractByIndex(_stakerAddress, i);
            scIndex = td.getStakerStakedContractIndex(_stakerAddress, i);
            unlockableAmount = _deprecated_getStakerUnlockableTokensOnSmartContract(
            _stakerAddress, scAddress,
            scIndex);
            td.setUnlockableBeforeLastBurnTokens(_stakerAddress, i, 0);
            td.pushUnlockedStakedTokens(_stakerAddress, i, unlockableAmount);
            reason = keccak256(abi.encodePacked("UW", _stakerAddress, scAddress, scIndex));
            tc.releaseLockedTokens(_stakerAddress, reason, unlockableAmount);
        }
    }

    /**
     * @dev to get tokens of staker locked before burning that are allowed to burn
     * @param stakerAdd is the address of the staker
     * @param stakedAdd is the address of staked contract in concern
     * @param stakerIndex is the staker index in concern
     * @return amount of unlockable tokens
     * @return amount of tokens that can burn
     */
    function _deprecated_unlockableBeforeBurningAndCanBurn(
        address stakerAdd,
        address stakedAdd,
        uint stakerIndex
    )
    public
    view
    returns
    (uint amount, uint canBurn) {

        uint dateAdd;
        uint initialStake;
        uint totalBurnt;
        uint ub;
        (, , dateAdd, initialStake, , totalBurnt, ub) = td.stakerStakedContracts(stakerAdd, stakerIndex);
        canBurn = _deprecated_calculateStakedTokens(initialStake, now.sub(dateAdd).div(1 days), td.scValidDays());
        // Can't use SafeMaths for int.
        int v = int(initialStake - (canBurn) - (totalBurnt) - (
            td.getStakerUnlockedStakedTokens(stakerAdd, stakerIndex)) - (ub));
        uint currentLockedTokens = _deprecated_getStakerLockedTokensOnSmartContract(
            stakerAdd, stakedAdd, td.getStakerStakedContractIndex(stakerAdd, stakerIndex));
        if (v < 0) {
            v = 0;
        }
        amount = uint(v);
        if (canBurn > currentLockedTokens.sub(amount).sub(ub)) {
            canBurn = currentLockedTokens.sub(amount).sub(ub);
        }
    }

    /**
     * @dev to get tokens of staker that are unlockable
     * @param _stakerAddress is the address of the staker
     * @param _stakedContractAddress is the address of staked contract in concern
     * @param _stakedContractIndex is the staked contract index in concern
     * @return amount of unlockable tokens
     */
    function _deprecated_getStakerUnlockableTokensOnSmartContract (
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        public
        view
        returns
        (uint amount)
    {
        uint initialStake;
        uint stakerIndex = td.getStakedContractStakerIndex(
            _stakedContractAddress, _stakedContractIndex);
        uint burnt;
        (, , , initialStake, , burnt,) = td.stakerStakedContracts(_stakerAddress, stakerIndex);
        uint alreadyUnlocked = td.getStakerUnlockedStakedTokens(_stakerAddress, stakerIndex);
        uint currentStakedTokens;
        (, currentStakedTokens) = _deprecated_unlockableBeforeBurningAndCanBurn(_stakerAddress,
            _stakedContractAddress, stakerIndex);
        amount = initialStake.sub(currentStakedTokens).sub(alreadyUnlocked).sub(burnt);
    }

    /**
     * @dev Internal function to get the amount of locked NXM tokens,
     * staked against smartcontract by index
     * @param _stakerAddress address of user
     * @param _stakedContractAddress staked contract address
     * @param _stakedContractIndex index of staking
     */
    function _deprecated_getStakerLockedTokensOnSmartContract (
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        internal
        view
        returns
        (uint amount)
    {
        bytes32 reason = keccak256(abi.encodePacked("UW", _stakerAddress,
            _stakedContractAddress, _stakedContractIndex));
        amount = tc.tokensLocked(_stakerAddress, reason);
    }

    /**
     * @dev Returns amount of NXM Tokens locked as Cover Note for given coverId.
     * @param _coverId coverId of the cover.
     */
    function _getLockedCNAgainstCover(uint _coverId) internal view returns(uint) {
        address coverHolder = qd.getCoverMemberAddress(_coverId);
        bytes32 reason = keccak256(abi.encodePacked("CN", coverHolder, _coverId));
        return tc.tokensLockedAtTime(coverHolder, reason, now);
    }

    /**
     * @dev Returns amount of NXM Tokens locked as Cover Note for given coverId.
     * @param _of address of the coverHolder.
     * @param _coverId coverId of the cover.
     */
    function _getUserLockedCNTokens(address _of, uint _coverId) internal view returns(uint) {
        bytes32 reason = keccak256(abi.encodePacked("CN", _of, _coverId));
        return tc.tokensLockedAtTime(_of, reason, now);
    }

    /**
     * @dev Internal function to gets remaining amount of staked NXM tokens,
     * against smartcontract by index
     * @param _stakeAmount address of user
     * @param _stakeDays staked contract address
     * @param _validDays index of staking
     */
    function _deprecated_calculateStakedTokens(
        uint _stakeAmount,
        uint _stakeDays,
        uint _validDays
    )
        internal
        pure
        returns (uint amount)
    {
        if (_validDays > _stakeDays) {
            uint rf = ((_validDays.sub(_stakeDays)).mul(100000)).div(_validDays);
            amount = (rf.mul(_stakeAmount)).div(100000);
        } else {
            amount = 0;
        }
    }

    /**
     * @dev Gets the total staked NXM tokens against Smart contract
     * by all stakers
     * @param _stakedContractAddress smart contract address.
     * @return amount total staked NXM tokens.
     */
    function _deprecated_burnStakerTokenLockedAgainstSmartContract(
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex,
        uint _amount
    )
        internal
    {
        uint stakerIndex = td.getStakedContractStakerIndex(
            _stakedContractAddress, _stakedContractIndex);
        td.pushBurnedTokens(_stakerAddress, stakerIndex, _amount);
        bytes32 reason = keccak256(abi.encodePacked("UW", _stakerAddress,
            _stakedContractAddress, _stakedContractIndex));
        tc.burnLockedTokens(_stakerAddress, reason, _amount);
    }
}

// File: nexusmutual-contracts/contracts/external/govblocks-protocol/interfaces/IMemberRoles.sol

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract IMemberRoles {

    event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);
    
    /// @dev Adds new member role
    /// @param _roleName New role name
    /// @param _roleDescription New description hash
    /// @param _authorized Authorized member against every role id
    function addRole(bytes32 _roleName, string memory _roleDescription, address _authorized) public;

    /// @dev Assign or Delete a member from specific role.
    /// @param _memberAddress Address of Member
    /// @param _roleId RoleId to update
    /// @param _active active is set to be True if we want to assign this role to member, False otherwise!
    function updateRole(address _memberAddress, uint _roleId, bool _active) public;

    /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
    /// @param _roleId roleId to update its Authorized Address
    /// @param _authorized New authorized address against role id
    function changeAuthorized(uint _roleId, address _authorized) public;

    /// @dev Return number of member roles
    function totalRoles() public view returns(uint256);

    /// @dev Gets the member addresses assigned by a specific role
    /// @param _memberRoleId Member role id
    /// @return roleId Role id
    /// @return allMemberAddress Member addresses of specified role id
    function members(uint _memberRoleId) public view returns(uint, address[] memory allMemberAddress);

    /// @dev Gets all members' length
    /// @param _memberRoleId Member role id
    /// @return memberRoleData[_memberRoleId].memberAddress.length Member length
    function numberOfMembers(uint _memberRoleId) public view returns(uint);
    
    /// @dev Return member address who holds the right to add/remove any member from specific role.
    function authorized(uint _memberRoleId) public view returns(address);

    /// @dev Get All role ids array that has been assigned to a member so far.
    function roles(address _memberAddress) public view returns(uint[] memory assignedRoles);

    /// @dev Returns true if the given role id is assigned to a member.
    /// @param _memberAddress Address of member
    /// @param _roleId Checks member's authenticity with the roleId.
    /// i.e. Returns true if this roleId is assigned to member
    function checkRole(address _memberAddress, uint _roleId) public view returns(bool);   
}

// File: nexusmutual-contracts/contracts/external/ERC1132/IERC1132.sol

pragma solidity 0.5.7;

/**
 * @title ERC1132 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1132
 */

contract IERC1132 {
    /**
     * @dev Reasons why a user's tokens have been locked
     */
    mapping(address => bytes32[]) public lockReason;

    /**
     * @dev locked token structure
     */
    struct LockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

    /**
     * @dev Holds number & validity of tokens locked for a given reason for
     *      a specified address
     */
    mapping(address => mapping(bytes32 => LockToken)) public locked;

    /**
     * @dev Records data of all the tokens Locked
     */
    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

    /**
     * @dev Records data of all the tokens unlocked
     */
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );
    
    /**
     * @dev Locks a specified amount of tokens against an address,
     *      for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be locked
     * @param _time Lock time in seconds
     */
    function lock(bytes32 _reason, uint256 _amount, uint256 _time)
        public returns (bool);
  
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensLocked(address _of, bytes32 _reason)
        public view returns (uint256 amount);
    
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason at a specific time
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public view returns (uint256 amount);
    
    /**
     * @dev Returns total tokens held by an address (locked + transferable)
     * @param _of The address to query the total balance of
     */
    function totalBalanceOf(address _of)
        public view returns (uint256 amount);
    
    /**
     * @dev Extends lock for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _time Lock extension time in seconds
     */
    function extendLock(bytes32 _reason, uint256 _time)
        public returns (bool);
    
    /**
     * @dev Increase number of tokens locked for a specified reason
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be increased
     */
    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public returns (bool);

    /**
     * @dev Returns unlockable tokens for a specified address for a specified reason
     * @param _of The address to query the the unlockable token count of
     * @param _reason The reason to query the unlockable tokens for
     */
    function tokensUnlockable(address _of, bytes32 _reason)
        public view returns (uint256 amount);
 
    /**
     * @dev Unlocks the unlockable tokens of a specified address
     * @param _of Address of user, claiming back unlockable tokens
     */
    function unlock(address _of)
        public returns (uint256 unlockableTokens);

    /**
     * @dev Gets the unlockable tokens of a specified address
     * @param _of The address to query the the unlockable token count of
     */
    function getUnlockableTokens(address _of)
        public view returns (uint256 unlockableTokens);

}

// File: nexusmutual-contracts/contracts/TokenController.sol

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;






contract TokenController is IERC1132, Iupgradable {
    using SafeMath for uint256;

    event Burned(address indexed member, bytes32 lockedUnder, uint256 amount);

    NXMToken public token;
    IPooledStaking public pooledStaking;
    uint public minCALockTime = uint(30).mul(1 days);
    bytes32 private constant CLA = bytes32("CLA");

    /**
    * @dev Just for interface
    */
    function changeDependentContractAddress() public {
        token = NXMToken(ms.tokenAddress());
        pooledStaking = IPooledStaking(ms.getLatestAddress('PS'));
    }

    /**
     * @dev to change the operator address
     * @param _newOperator is the new address of operator
     */
    function changeOperator(address _newOperator) public onlyInternal {
        token.changeOperator(_newOperator);
    }

    /**
     * @dev Proxies token transfer through this contract to allow staking when members are locked for voting
     * @param _from   Source address
     * @param _to     Destination address
     * @param _value  Amount to transfer
     */
    function operatorTransfer(address _from, address _to, uint _value) onlyInternal external returns (bool) {
        require(msg.sender == address(pooledStaking), "Call is only allowed from PooledStaking address");
        require(token.operatorTransfer(_from, _value), "Operator transfer failed");
        require(token.transfer(_to, _value), "Internal transfer failed");
        return true;
    }

    /**
    * @dev Locks a specified amount of tokens,
    *    for CLA reason and for a specified time
    * @param _reason The reason to lock tokens, currently restricted to CLA
    * @param _amount Number of tokens to be locked
    * @param _time Lock time in seconds
    */
    function lock(bytes32 _reason, uint256 _amount, uint256 _time) public checkPause returns (bool)
    {
        require(_reason == CLA,"Restricted to reason CLA");
        require(minCALockTime <= _time,"Should lock for minimum time");
        // If tokens are already locked, then functions extendLock or
        // increaseLockAmount should be used to make any changes
        _lock(msg.sender, _reason, _amount, _time);
        return true;
    }

    /**
    * @dev Locks a specified amount of tokens against an address,
    *    for a specified reason and time
    * @param _reason The reason to lock tokens
    * @param _amount Number of tokens to be locked
    * @param _time Lock time in seconds
    * @param _of address whose tokens are to be locked
    */
    function lockOf(address _of, bytes32 _reason, uint256 _amount, uint256 _time)
        public
        onlyInternal
        returns (bool)
    {
        // If tokens are already locked, then functions extendLock or
        // increaseLockAmount should be used to make any changes
        _lock(_of, _reason, _amount, _time);
        return true;
    }

    /**
    * @dev Extends lock for reason CLA for a specified time
    * @param _reason The reason to lock tokens, currently restricted to CLA
    * @param _time Lock extension time in seconds
    */
    function extendLock(bytes32 _reason, uint256 _time)
        public
        checkPause
        returns (bool)
    {
        require(_reason == CLA,"Restricted to reason CLA");
        _extendLock(msg.sender, _reason, _time);
        return true;
    }

    /**
    * @dev Extends lock for a specified reason and time
    * @param _reason The reason to lock tokens
    * @param _time Lock extension time in seconds
    */
    function extendLockOf(address _of, bytes32 _reason, uint256 _time)
        public
        onlyInternal
        returns (bool)
    {
        _extendLock(_of, _reason, _time);
        return true;
    }

    /**
    * @dev Increase number of tokens locked for a CLA reason
    * @param _reason The reason to lock tokens, currently restricted to CLA
    * @param _amount Number of tokens to be increased
    */
    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public
        checkPause
        returns (bool)
    {    
        require(_reason == CLA,"Restricted to reason CLA");
        require(_tokensLocked(msg.sender, _reason) > 0);
        token.operatorTransfer(msg.sender, _amount);

        locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount.add(_amount);
        emit Locked(msg.sender, _reason, _amount, locked[msg.sender][_reason].validity);
        return true;
    }

    /**
     * @dev burns tokens of an address
     * @param _of is the address to burn tokens of
     * @param amount is the amount to burn
     * @return the boolean status of the burning process
     */
    function burnFrom (address _of, uint amount) public onlyInternal returns (bool) {
        return token.burnFrom(_of, amount);
    }

    /**
    * @dev Burns locked tokens of a user
    * @param _of address whose tokens are to be burned
    * @param _reason lock reason for which tokens are to be burned
    * @param _amount amount of tokens to burn
    */
    function burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) public onlyInternal {
        _burnLockedTokens(_of, _reason, _amount);
    }

    /**
    * @dev reduce lock duration for a specified reason and time
    * @param _of The address whose tokens are locked
    * @param _reason The reason to lock tokens
    * @param _time Lock reduction time in seconds
    */
    function reduceLock(address _of, bytes32 _reason, uint256 _time) public onlyInternal {
        _reduceLock(_of, _reason, _time);
    }

    /**
    * @dev Released locked tokens of an address locked for a specific reason
    * @param _of address whose tokens are to be released from lock
    * @param _reason reason of the lock
    * @param _amount amount of tokens to release
    */
    function releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount)
        public
        onlyInternal
    {
        _releaseLockedTokens(_of, _reason, _amount);
    }

    /**
    * @dev Adds an address to whitelist maintained in the contract
    * @param _member address to add to whitelist
    */
    function addToWhitelist(address _member) public onlyInternal {
        token.addToWhiteList(_member);
    }

    /**
    * @dev Removes an address from the whitelist in the token
    * @param _member address to remove
    */
    function removeFromWhitelist(address _member) public onlyInternal {
        token.removeFromWhiteList(_member);
    }

    /**
    * @dev Mints new token for an address
    * @param _member address to reward the minted tokens
    * @param _amount number of tokens to mint
    */
    function mint(address _member, uint _amount) public onlyInternal {
        token.mint(_member, _amount);
    }

    /**
     * @dev Lock the user's tokens
     * @param _of user's address.
     */
    function lockForMemberVote(address _of, uint _days) public onlyInternal {
        token.lockForMemberVote(_of, _days);
    }

    /**
    * @dev Unlocks the unlockable tokens against CLA of a specified address
    * @param _of Address of user, claiming back unlockable tokens against CLA
    */
    function unlock(address _of)
        public
        checkPause
        returns (uint256 unlockableTokens)
    {
        unlockableTokens = _tokensUnlockable(_of, CLA);
        if (unlockableTokens > 0) {
            locked[_of][CLA].claimed = true;
            emit Unlocked(_of, CLA, unlockableTokens);
            require(token.transfer(_of, unlockableTokens));
        }
    }

    /**
     * @dev Updates Uint Parameters of a code
     * @param code whose details we want to update
     * @param val value to set
     */
    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "MNCLT") {
            minCALockTime = val.mul(1 days);
        } else {
            revert("Invalid param code");
        }
    }

    /**
    * @dev Gets the validity of locked tokens of a specified address
    * @param _of The address to query the validity
    * @param reason reason for which tokens were locked
    */
    function getLockedTokensValidity(address _of, bytes32 reason)
        public
        view
        returns (uint256 validity)
    {
        validity = locked[_of][reason].validity;
    }

    /**
    * @dev Gets the unlockable tokens of a specified address
    * @param _of The address to query the the unlockable token count of
    */
    function getUnlockableTokens(address _of)
        public
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens = unlockableTokens.add(_tokensUnlockable(_of, lockReason[_of][i]));
        }
    }

    /**
    * @dev Returns tokens locked for a specified address for a
    *    specified reason
    *
    * @param _of The address whose tokens are locked
    * @param _reason The reason to query the lock tokens for
    */
    function tokensLocked(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        return _tokensLocked(_of, _reason);
    }

    /**
    * @dev Returns unlockable tokens for a specified address for a specified reason
    * @param _of The address to query the the unlockable token count of
    * @param _reason The reason to query the unlockable tokens for
    */
    function tokensUnlockable(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        return _tokensUnlockable(_of, _reason);
    }

    function totalSupply() public view returns (uint256)
    {
        return token.totalSupply();
    }

    /**
    * @dev Returns tokens locked for a specified address for a
    *    specified reason at a specific time
    *
    * @param _of The address whose tokens are locked
    * @param _reason The reason to query the lock tokens for
    * @param _time The timestamp to query the lock tokens for
    */
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        return _tokensLockedAtTime(_of, _reason, _time);
    }

    /**
    * @dev Returns the total amount of tokens held by an address:
    *   transferable + locked + staked for pooled staking - pending burns.
    *   Used by Claims and Governance in member voting to calculate the user's vote weight.
    *
    * @param _of The address to query the total balance of
    * @param _of The address to query the total balance of
    */
    function totalBalanceOf(address _of) public view returns (uint256 amount) {

        amount = token.balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(_tokensLocked(_of, lockReason[_of][i]));
        }

        uint stakerReward = pooledStaking.stakerReward(_of);
        uint stakerDeposit = pooledStaking.stakerDeposit(_of);

        amount = amount.add(stakerDeposit).add(stakerReward);
    }

    /**
    * @dev Returns the total locked tokens at time
    *   Returns the total amount of locked and staked tokens at a given time. Used by MemberRoles to check eligibility
    *   for withdraw / switch membership. Includes tokens locked for Claim Assessment and staked for Risk Assessment.
    *   Does not take into account pending burns.
    *
    * @param _of member whose locked tokens are to be calculate
    * @param _time timestamp when the tokens should be locked
    */
    function totalLockedBalance(address _of, uint256 _time) public view returns (uint256 amount) {

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(_tokensLockedAtTime(_of, lockReason[_of][i], _time));
        }

        amount = amount.add(pooledStaking.stakerDeposit(_of));
    }

    /**
    * @dev Locks a specified amount of tokens against an address,
    *    for a specified reason and time
    * @param _of address whose tokens are to be locked
    * @param _reason The reason to lock tokens
    * @param _amount Number of tokens to be locked
    * @param _time Lock time in seconds
    */
    function _lock(address _of, bytes32 _reason, uint256 _amount, uint256 _time) internal {
        require(_tokensLocked(_of, _reason) == 0);
        require(_amount != 0);

        if (locked[_of][_reason].amount == 0) {
            lockReason[_of].push(_reason);
        }

        require(token.operatorTransfer(_of, _amount));

        uint256 validUntil = now.add(_time); //solhint-disable-line
        locked[_of][_reason] = LockToken(_amount, validUntil, false);
        emit Locked(_of, _reason, _amount, validUntil);
    }

    /**
    * @dev Returns tokens locked for a specified address for a
    *    specified reason
    *
    * @param _of The address whose tokens are locked
    * @param _reason The reason to query the lock tokens for
    */
    function _tokensLocked(address _of, bytes32 _reason)
        internal
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed) {
            amount = locked[_of][_reason].amount;
        }
    }

    /**
    * @dev Returns tokens locked for a specified address for a
    *    specified reason at a specific time
    *
    * @param _of The address whose tokens are locked
    * @param _reason The reason to query the lock tokens for
    * @param _time The timestamp to query the lock tokens for
    */
    function _tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        internal
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time) {
            amount = locked[_of][_reason].amount;
        }
    }

    /**
    * @dev Extends lock for a specified reason and time
    * @param _of The address whose tokens are locked
    * @param _reason The reason to lock tokens
    * @param _time Lock extension time in seconds
    */
    function _extendLock(address _of, bytes32 _reason, uint256 _time) internal {
        require(_tokensLocked(_of, _reason) > 0);
        emit Unlocked(_of, _reason, locked[_of][_reason].amount);
        locked[_of][_reason].validity = locked[_of][_reason].validity.add(_time);
        emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
    }

    /**
    * @dev reduce lock duration for a specified reason and time
    * @param _of The address whose tokens are locked
    * @param _reason The reason to lock tokens
    * @param _time Lock reduction time in seconds
    */
    function _reduceLock(address _of, bytes32 _reason, uint256 _time) internal {
        require(_tokensLocked(_of, _reason) > 0);
        emit Unlocked(_of, _reason, locked[_of][_reason].amount);
        locked[_of][_reason].validity = locked[_of][_reason].validity.sub(_time);
        emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
    }

    /**
    * @dev Returns unlockable tokens for a specified address for a specified reason
    * @param _of The address to query the the unlockable token count of
    * @param _reason The reason to query the unlockable tokens for
    */
    function _tokensUnlockable(address _of, bytes32 _reason) internal view returns (uint256 amount)
    {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) {
            amount = locked[_of][_reason].amount;
        }
    }

    /**
    * @dev Burns locked tokens of a user
    * @param _of address whose tokens are to be burned
    * @param _reason lock reason for which tokens are to be burned
    * @param _amount amount of tokens to burn
    */
    function _burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) internal {
        uint256 amount = _tokensLocked(_of, _reason);
        require(amount >= _amount);

        if (amount == _amount) {
            locked[_of][_reason].claimed = true;
        }

        locked[_of][_reason].amount = locked[_of][_reason].amount.sub(_amount);
        if (locked[_of][_reason].amount == 0) {
            _removeReason(_of, _reason);
        }
        token.burn(_amount);
        emit Burned(_of, _reason, _amount);
    }

    /**
    * @dev Released locked tokens of an address locked for a specific reason
    * @param _of address whose tokens are to be released from lock
    * @param _reason reason of the lock
    * @param _amount amount of tokens to release
    */
    function _releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount) internal
    {
        uint256 amount = _tokensLocked(_of, _reason);
        require(amount >= _amount);

        if (amount == _amount) {
            locked[_of][_reason].claimed = true;
        }

        locked[_of][_reason].amount = locked[_of][_reason].amount.sub(_amount);
        if (locked[_of][_reason].amount == 0) {
            _removeReason(_of, _reason);
        }
        require(token.transfer(_of, _amount));
        emit Unlocked(_of, _reason, _amount);
    }

    function _removeReason(address _of, bytes32 _reason) internal {
        uint len = lockReason[_of].length;
        for (uint i = 0; i < len; i++) {
            if (lockReason[_of][i] == _reason) {
                lockReason[_of][i] = lockReason[_of][len.sub(1)];
                lockReason[_of].pop();
                break;
            }
        }   
    }
}

// File: nexusmutual-contracts/contracts/ClaimsData.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;




contract ClaimsData is Iupgradable {
    using SafeMath for uint;

    struct Claim {
        uint coverId;
        uint dateUpd;
    }

    struct Vote {
        address voter;
        uint tokens;
        uint claimId;
        int8 verdict;
        bool rewardClaimed;
    }

    struct ClaimsPause {
        uint coverid;
        uint dateUpd;
        bool submit;
    }

    struct ClaimPauseVoting {
        uint claimid;
        uint pendingTime;
        bool voting;
    }

    struct RewardDistributed {
        uint lastCAvoteIndex;
        uint lastMVvoteIndex;

    }

    struct ClaimRewardDetails {
        uint percCA;
        uint percMV;
        uint tokenToBeDist;

    }

    struct ClaimTotalTokens {
        uint accept;
        uint deny;
    }

    struct ClaimRewardStatus {
        uint percCA;
        uint percMV;
    }

    ClaimRewardStatus[] internal rewardStatus;

    Claim[] internal allClaims;
    Vote[] internal allvotes;
    ClaimsPause[] internal claimPause;
    ClaimPauseVoting[] internal claimPauseVotingEP;

    mapping(address => RewardDistributed) internal voterVoteRewardReceived;
    mapping(uint => ClaimRewardDetails) internal claimRewardDetail;
    mapping(uint => ClaimTotalTokens) internal claimTokensCA;
    mapping(uint => ClaimTotalTokens) internal claimTokensMV;
    mapping(uint => int8) internal claimVote;
    mapping(uint => uint) internal claimsStatus;
    mapping(uint => uint) internal claimState12Count;
    mapping(uint => uint[]) internal claimVoteCA;
    mapping(uint => uint[]) internal claimVoteMember;
    mapping(address => uint[]) internal voteAddressCA;
    mapping(address => uint[]) internal voteAddressMember;
    mapping(address => uint[]) internal allClaimsByAddress;
    mapping(address => mapping(uint => uint)) internal userClaimVoteCA;
    mapping(address => mapping(uint => uint)) internal userClaimVoteMember;
    mapping(address => uint) public userClaimVotePausedOn;

    uint internal claimPauseLastsubmit;
    uint internal claimStartVotingFirstIndex;
    uint public pendingClaimStart;
    uint public claimDepositTime;
    uint public maxVotingTime;
    uint public minVotingTime;
    uint public payoutRetryTime;
    uint public claimRewardPerc;
    uint public minVoteThreshold;
    uint public maxVoteThreshold;
    uint public majorityConsensus;
    uint public pauseDaysCA;
   
    event ClaimRaise(
        uint indexed coverId,
        address indexed userAddress,
        uint claimId,
        uint dateSubmit
    );

    event VoteCast(
        address indexed userAddress,
        uint indexed claimId,
        bytes4 indexed typeOf,
        uint tokens,
        uint submitDate,
        int8 verdict
    );

    constructor() public {
        pendingClaimStart = 1;
        maxVotingTime = 48 * 1 hours;
        minVotingTime = 12 * 1 hours;
        payoutRetryTime = 24 * 1 hours;
        allvotes.push(Vote(address(0), 0, 0, 0, false));
        allClaims.push(Claim(0, 0));
        claimDepositTime = 7 days;
        claimRewardPerc = 20;
        minVoteThreshold = 5;
        maxVoteThreshold = 10;
        majorityConsensus = 70;
        pauseDaysCA = 3 days;
        _addRewardIncentive();
    }

    /**
     * @dev Updates the pending claim start variable, 
     * the lowest claim id with a pending decision/payout.
     */ 
    function setpendingClaimStart(uint _start) external onlyInternal {
        require(pendingClaimStart <= _start);
        pendingClaimStart = _start;
    }

    /** 
     * @dev Updates the max vote index for which claim assessor has received reward 
     * @param _voter address of the voter.
     * @param caIndex last index till which reward was distributed for CA
     */ 
    function setRewardDistributedIndexCA(address _voter, uint caIndex) external onlyInternal {
        voterVoteRewardReceived[_voter].lastCAvoteIndex = caIndex;

    }

    /** 
     * @dev Used to pause claim assessor activity for 3 days 
     * @param user Member address whose claim voting ability needs to be paused
     */ 
    function setUserClaimVotePausedOn(address user) external {
        require(ms.checkIsAuthToGoverned(msg.sender));
        userClaimVotePausedOn[user] = now;
    }

    /**
     * @dev Updates the max vote index for which member has received reward 
     * @param _voter address of the voter.
     * @param mvIndex last index till which reward was distributed for member 
     */ 
    function setRewardDistributedIndexMV(address _voter, uint mvIndex) external onlyInternal {

        voterVoteRewardReceived[_voter].lastMVvoteIndex = mvIndex;
    }

    /**
     * @param claimid claim id.
     * @param percCA reward Percentage reward for claim assessor
     * @param percMV reward Percentage reward for members
     * @param tokens total tokens to be rewarded
     */ 
    function setClaimRewardDetail(
        uint claimid,
        uint percCA,
        uint percMV,
        uint tokens
    )
        external
        onlyInternal
    {
        claimRewardDetail[claimid].percCA = percCA;
        claimRewardDetail[claimid].percMV = percMV;
        claimRewardDetail[claimid].tokenToBeDist = tokens;
    }

    /**
     * @dev Sets the reward claim status against a vote id.
     * @param _voteid vote Id.
     * @param claimed true if reward for vote is claimed, else false.
     */ 
    function setRewardClaimed(uint _voteid, bool claimed) external onlyInternal {
        allvotes[_voteid].rewardClaimed = claimed;
    }

    /**
     * @dev Sets the final vote's result(either accepted or declined)of a claim.
     * @param _claimId Claim Id.
     * @param _verdict 1 if claim is accepted,-1 if declined.
     */ 
    function changeFinalVerdict(uint _claimId, int8 _verdict) external onlyInternal {
        claimVote[_claimId] = _verdict;
    }
    
    /**
     * @dev Creates a new claim.
     */ 
    function addClaim(
        uint _claimId,
        uint _coverId,
        address _from,
        uint _nowtime
    )
        external
        onlyInternal
    {
        allClaims.push(Claim(_coverId, _nowtime));
        allClaimsByAddress[_from].push(_claimId);
    }

    /**
     * @dev Add Vote's details of a given claim.
     */ 
    function addVote(
        address _voter,
        uint _tokens,
        uint claimId,
        int8 _verdict
    ) 
        external
        onlyInternal
    {
        allvotes.push(Vote(_voter, _tokens, claimId, _verdict, false));
    }

    /** 
     * @dev Stores the id of the claim assessor vote given to a claim.
     * Maintains record of all votes given by all the CA to a claim.
     * @param _claimId Claim Id to which vote has given by the CA.
     * @param _voteid Vote Id.
     */
    function addClaimVoteCA(uint _claimId, uint _voteid) external onlyInternal {
        claimVoteCA[_claimId].push(_voteid);
    }

    /** 
     * @dev Sets the id of the vote.
     * @param _from Claim assessor's address who has given the vote.
     * @param _claimId Claim Id for which vote has been given by the CA.
     * @param _voteid Vote Id which will be stored against the given _from and claimid.
     */ 
    function setUserClaimVoteCA(
        address _from,
        uint _claimId,
        uint _voteid
    )
        external
        onlyInternal
    {
        userClaimVoteCA[_from][_claimId] = _voteid;
        voteAddressCA[_from].push(_voteid);
    }

    /**
     * @dev Stores the tokens locked by the Claim Assessors during voting of a given claim.
     * @param _claimId Claim Id.
     * @param _vote 1 for accept and increases the tokens of claim as accept,
     * -1 for deny and increases the tokens of claim as deny.
     * @param _tokens Number of tokens.
     */ 
    function setClaimTokensCA(uint _claimId, int8 _vote, uint _tokens) external onlyInternal {
        if (_vote == 1)
            claimTokensCA[_claimId].accept = claimTokensCA[_claimId].accept.add(_tokens);
        if (_vote == -1)
            claimTokensCA[_claimId].deny = claimTokensCA[_claimId].deny.add(_tokens);
    }

    /** 
     * @dev Stores the tokens locked by the Members during voting of a given claim.
     * @param _claimId Claim Id.
     * @param _vote 1 for accept and increases the tokens of claim as accept,
     * -1 for deny and increases the tokens of claim as deny.
     * @param _tokens Number of tokens.
     */ 
    function setClaimTokensMV(uint _claimId, int8 _vote, uint _tokens) external onlyInternal {
        if (_vote == 1)
            claimTokensMV[_claimId].accept = claimTokensMV[_claimId].accept.add(_tokens);
        if (_vote == -1)
            claimTokensMV[_claimId].deny = claimTokensMV[_claimId].deny.add(_tokens);
    }

    /** 
     * @dev Stores the id of the member vote given to a claim.
     * Maintains record of all votes given by all the Members to a claim.
     * @param _claimId Claim Id to which vote has been given by the Member.
     * @param _voteid Vote Id.
     */ 
    function addClaimVotemember(uint _claimId, uint _voteid) external onlyInternal {
        claimVoteMember[_claimId].push(_voteid);
    }

    /** 
     * @dev Sets the id of the vote.
     * @param _from Member's address who has given the vote.
     * @param _claimId Claim Id for which vote has been given by the Member.
     * @param _voteid Vote Id which will be stored against the given _from and claimid.
     */ 
    function setUserClaimVoteMember(
        address _from,
        uint _claimId,
        uint _voteid
    )
        external
        onlyInternal
    {
        userClaimVoteMember[_from][_claimId] = _voteid;
        voteAddressMember[_from].push(_voteid);

    }

    /** 
     * @dev Increases the count of failure until payout of a claim is successful.
     */ 
    function updateState12Count(uint _claimId, uint _cnt) external onlyInternal {
        claimState12Count[_claimId] = claimState12Count[_claimId].add(_cnt);
    }

    /** 
     * @dev Sets status of a claim.
     * @param _claimId Claim Id.
     * @param _stat Status number.
     */
    function setClaimStatus(uint _claimId, uint _stat) external onlyInternal {
        claimsStatus[_claimId] = _stat;
    }

    /** 
     * @dev Sets the timestamp of a given claim at which the Claim's details has been updated.
     * @param _claimId Claim Id of claim which has been changed.
     * @param _dateUpd timestamp at which claim is updated.
     */ 
    function setClaimdateUpd(uint _claimId, uint _dateUpd) external onlyInternal {
        allClaims[_claimId].dateUpd = _dateUpd;
    }

    /** 
     @dev Queues Claims during Emergency Pause.
     */ 
    function setClaimAtEmergencyPause(
        uint _coverId,
        uint _dateUpd,
        bool _submit
    )
        external
        onlyInternal
    {
        claimPause.push(ClaimsPause(_coverId, _dateUpd, _submit));
    }

    /** 
     * @dev Set submission flag for Claims queued during emergency pause.
     * Set to true after EP is turned off and the claim is submitted .
     */ 
    function setClaimSubmittedAtEPTrue(uint _index, bool _submit) external onlyInternal {
        claimPause[_index].submit = _submit;
    }

    /** 
     * @dev Sets the index from which claim needs to be 
     * submitted when emergency pause is swithched off.
     */ 
    function setFirstClaimIndexToSubmitAfterEP(
        uint _firstClaimIndexToSubmit
    )
        external
        onlyInternal
    {
        claimPauseLastsubmit = _firstClaimIndexToSubmit;
    }

    /** 
     * @dev Sets the pending vote duration for a claim in case of emergency pause.
     */ 
    function setPendingClaimDetails(
        uint _claimId,
        uint _pendingTime,
        bool _voting
    )
        external
        onlyInternal
    {
        claimPauseVotingEP.push(ClaimPauseVoting(_claimId, _pendingTime, _voting));
    }

    /** 
     * @dev Sets voting flag true after claim is reopened for voting after emergency pause.
     */ 
    function setPendingClaimVoteStatus(uint _claimId, bool _vote) external onlyInternal {
        claimPauseVotingEP[_claimId].voting = _vote;
    }
    
    /** 
     * @dev Sets the index from which claim needs to be 
     * reopened when emergency pause is swithched off. 
     */ 
    function setFirstClaimIndexToStartVotingAfterEP(
        uint _claimStartVotingFirstIndex
    )
        external
        onlyInternal
    {
        claimStartVotingFirstIndex = _claimStartVotingFirstIndex;
    }

    /** 
     * @dev Calls Vote Event.
     */ 
    function callVoteEvent(
        address _userAddress,
        uint _claimId,
        bytes4 _typeOf,
        uint _tokens,
        uint _submitDate,
        int8 _verdict
    )
        external
        onlyInternal
    {
        emit VoteCast(
            _userAddress,
            _claimId,
            _typeOf,
            _tokens,
            _submitDate,
            _verdict
        );
    }

    /** 
     * @dev Calls Claim Event. 
     */ 
    function callClaimEvent(
        uint _coverId,
        address _userAddress,
        uint _claimId,
        uint _datesubmit
    ) 
        external
        onlyInternal
    {
        emit ClaimRaise(_coverId, _userAddress, _claimId, _datesubmit);
    }

    /**
     * @dev Gets Uint Parameters by parameter code
     * @param code whose details we want
     * @return string value of the parameter
     * @return associated amount (time or perc or value) to the code
     */
    function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {
        codeVal = code;
        if (code == "CAMAXVT") {
            val = maxVotingTime / (1 hours);

        } else if (code == "CAMINVT") {

            val = minVotingTime / (1 hours);

        } else if (code == "CAPRETRY") {

            val = payoutRetryTime / (1 hours);

        } else if (code == "CADEPT") {

            val = claimDepositTime / (1 days);

        } else if (code == "CAREWPER") {

            val = claimRewardPerc;

        } else if (code == "CAMINTH") {

            val = minVoteThreshold;

        } else if (code == "CAMAXTH") {

            val = maxVoteThreshold;

        } else if (code == "CACONPER") {

            val = majorityConsensus;

        } else if (code == "CAPAUSET") {
            val = pauseDaysCA / (1 days);
        }
    
    }

    /**
     * @dev Get claim queued during emergency pause by index.
     */ 
    function getClaimOfEmergencyPauseByIndex(
        uint _index
    ) 
        external
        view
        returns(
            uint coverId,
            uint dateUpd,
            bool submit
        )
    {
        coverId = claimPause[_index].coverid;
        dateUpd = claimPause[_index].dateUpd;
        submit = claimPause[_index].submit;
    }

    /**
     * @dev Gets the Claim's details of given claimid.   
     */ 
    function getAllClaimsByIndex(
        uint _claimId
    )
        external
        view
        returns(
            uint coverId,
            int8 vote,
            uint status,
            uint dateUpd,
            uint state12Count
        )
    {
        return(
            allClaims[_claimId].coverId,
            claimVote[_claimId],
            claimsStatus[_claimId],
            allClaims[_claimId].dateUpd,
            claimState12Count[_claimId]
        );
    }

    /** 
     * @dev Gets the vote id of a given claim of a given Claim Assessor.
     */ 
    function getUserClaimVoteCA(
        address _add,
        uint _claimId
    )
        external
        view
        returns(uint idVote)
    {
        return userClaimVoteCA[_add][_claimId];
    }

    /** 
     * @dev Gets the vote id of a given claim of a given member.
     */
    function getUserClaimVoteMember(
        address _add,
        uint _claimId
    )
        external
        view
        returns(uint idVote)
    {
        return userClaimVoteMember[_add][_claimId];
    }

    /** 
     * @dev Gets the count of all votes.
     */ 
    function getAllVoteLength() external view returns(uint voteCount) {
        return allvotes.length.sub(1); //Start Index always from 1.
    }

    /**
     * @dev Gets the status number of a given claim.
     * @param _claimId Claim id.
     * @return statno Status Number. 
     */ 
    function getClaimStatusNumber(uint _claimId) external view returns(uint claimId, uint statno) {
        return (_claimId, claimsStatus[_claimId]);
    }

    /**
     * @dev Gets the reward percentage to be distributed for a given status id
     * @param statusNumber the number of type of status
     * @return percCA reward Percentage for claim assessor
     * @return percMV reward Percentage for members
     */
    function getRewardStatus(uint statusNumber) external view returns(uint percCA, uint percMV) {
        return (rewardStatus[statusNumber].percCA, rewardStatus[statusNumber].percMV);
    }

    /** 
     * @dev Gets the number of tries that have been made for a successful payout of a Claim.
     */ 
    function getClaimState12Count(uint _claimId) external view returns(uint num) {
        num = claimState12Count[_claimId];
    }

    /** 
     * @dev Gets the last update date of a claim.
     */ 
    function getClaimDateUpd(uint _claimId) external view returns(uint dateupd) {
        dateupd = allClaims[_claimId].dateUpd;
    }

    /**
     * @dev Gets all Claims created by a user till date.
     * @param _member user's address.
     * @return claimarr List of Claims id.
     */ 
    function getAllClaimsByAddress(address _member) external view returns(uint[] memory claimarr) {
        return allClaimsByAddress[_member];
    }

    /**
     * @dev Gets the number of tokens that has been locked 
     * while giving vote to a claim by  Claim Assessors.
     * @param _claimId Claim Id.
     * @return accept Total number of tokens when CA accepts the claim.
     * @return deny Total number of tokens when CA declines the claim.
     */ 
    function getClaimsTokenCA(
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint accept,
            uint deny
        )
    {
        return (
            _claimId,
            claimTokensCA[_claimId].accept,
            claimTokensCA[_claimId].deny
        );
    }

    /** 
     * @dev Gets the number of tokens that have been
     * locked while assessing a claim as a member.
     * @param _claimId Claim Id.
     * @return accept Total number of tokens in acceptance of the claim.
     * @return deny Total number of tokens against the claim.
     */ 
    function getClaimsTokenMV(
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint accept,
            uint deny
        )
    {
        return (
            _claimId,
            claimTokensMV[_claimId].accept,
            claimTokensMV[_claimId].deny
        );
    }

    /**
     * @dev Gets the total number of votes cast as Claims assessor for/against a given claim
     */ 
    function getCaClaimVotesToken(uint _claimId) external view returns(uint claimId, uint cnt) {
        claimId = _claimId;
        cnt = 0;
        for (uint i = 0; i < claimVoteCA[_claimId].length; i++) {
            cnt = cnt.add(allvotes[claimVoteCA[_claimId][i]].tokens);
        }
    }

    /**
     * @dev Gets the total number of tokens cast as a member for/against a given claim  
     */ 
    function getMemberClaimVotesToken(
        uint _claimId
    )   
        external
        view
        returns(uint claimId, uint cnt)
    {
        claimId = _claimId;
        cnt = 0;
        for (uint i = 0; i < claimVoteMember[_claimId].length; i++) {
            cnt = cnt.add(allvotes[claimVoteMember[_claimId][i]].tokens);
        }
    }

    /**
     * @dev Provides information of a vote when given its vote id.
     * @param _voteid Vote Id.
     */
    function getVoteDetails(uint _voteid)
    external view
    returns(
        uint tokens,
        uint claimId,
        int8 verdict,
        bool rewardClaimed
        )
    {
        return (
            allvotes[_voteid].tokens,
            allvotes[_voteid].claimId,
            allvotes[_voteid].verdict,
            allvotes[_voteid].rewardClaimed
        );
    }

    /**
     * @dev Gets the voter's address of a given vote id.
     */ 
    function getVoterVote(uint _voteid) external view returns(address voter) {
        return allvotes[_voteid].voter;
    }

    /**
     * @dev Provides information of a Claim when given its claim id.
     * @param _claimId Claim Id.
     */ 
    function getClaim(
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint coverId,
            int8 vote,
            uint status,
            uint dateUpd,
            uint state12Count
        )
    {
        return (
            _claimId,
            allClaims[_claimId].coverId,
            claimVote[_claimId],
            claimsStatus[_claimId],
            allClaims[_claimId].dateUpd,
            claimState12Count[_claimId]
            );
    }

    /**
     * @dev Gets the total number of votes of a given claim.
     * @param _claimId Claim Id.
     * @param _ca if 1: votes given by Claim Assessors to a claim,
     * else returns the number of votes of given by Members to a claim.
     * @return len total number of votes for/against a given claim.
     */ 
    function getClaimVoteLength(
        uint _claimId,
        uint8 _ca
    )
        external
        view
        returns(uint claimId, uint len)
    {
        claimId = _claimId;
        if (_ca == 1)
            len = claimVoteCA[_claimId].length;
        else
            len = claimVoteMember[_claimId].length;
    }

    /**
     * @dev Gets the verdict of a vote using claim id and index.
     * @param _ca 1 for vote given as a CA, else for vote given as a member.
     * @return ver 1 if vote was given in favour,-1 if given in against.
     */ 
    function getVoteVerdict(
        uint _claimId,
        uint _index,
        uint8 _ca
    )
        external
        view
        returns(int8 ver)
    {
        if (_ca == 1)
            ver = allvotes[claimVoteCA[_claimId][_index]].verdict;
        else
            ver = allvotes[claimVoteMember[_claimId][_index]].verdict;
    }

    /**
     * @dev Gets the Number of tokens of a vote using claim id and index.
     * @param _ca 1 for vote given as a CA, else for vote given as a member.
     * @return tok Number of tokens.
     */ 
    function getVoteToken(
        uint _claimId,
        uint _index,
        uint8 _ca
    )   
        external
        view
        returns(uint tok)
    {
        if (_ca == 1)
            tok = allvotes[claimVoteCA[_claimId][_index]].tokens;
        else
            tok = allvotes[claimVoteMember[_claimId][_index]].tokens;
    }

    /**
     * @dev Gets the Voter's address of a vote using claim id and index.
     * @param _ca 1 for vote given as a CA, else for vote given as a member.
     * @return voter Voter's address.
     */ 
    function getVoteVoter(
        uint _claimId,
        uint _index,
        uint8 _ca
    )
        external
        view
        returns(address voter)
    {
        if (_ca == 1)
            voter = allvotes[claimVoteCA[_claimId][_index]].voter;
        else
            voter = allvotes[claimVoteMember[_claimId][_index]].voter;
    }

    /** 
     * @dev Gets total number of Claims created by a user till date.
     * @param _add User's address.
     */ 
    function getUserClaimCount(address _add) external view returns(uint len) {
        len = allClaimsByAddress[_add].length;
    }

    /**
     * @dev Calculates number of Claims that are in pending state.
     */ 
    function getClaimLength() external view returns(uint len) {
        len = allClaims.length.sub(pendingClaimStart);
    }

    /**
     * @dev Gets the Number of all the Claims created till date.
     */ 
    function actualClaimLength() external view returns(uint len) {
        len = allClaims.length;
    }

    /** 
     * @dev Gets details of a claim.
     * @param _index claim id = pending claim start + given index
     * @param _add User's address.
     * @return coverid cover against which claim has been submitted.
     * @return claimId Claim  Id.
     * @return voteCA verdict of vote given as a Claim Assessor.  
     * @return voteMV verdict of vote given as a Member.
     * @return statusnumber Status of claim.
     */ 
    function getClaimFromNewStart(
        uint _index,
        address _add
    )
        external
        view
        returns(
            uint coverid,
            uint claimId,
            int8 voteCA,
            int8 voteMV,
            uint statusnumber
        )
    {
        uint i = pendingClaimStart.add(_index);
        coverid = allClaims[i].coverId;
        claimId = i;
        if (userClaimVoteCA[_add][i] > 0)
            voteCA = allvotes[userClaimVoteCA[_add][i]].verdict;
        else
            voteCA = 0;

        if (userClaimVoteMember[_add][i] > 0)
            voteMV = allvotes[userClaimVoteMember[_add][i]].verdict;
        else
            voteMV = 0;

        statusnumber = claimsStatus[i];
    }

    /**
     * @dev Gets details of a claim of a user at a given index.  
     */ 
    function getUserClaimByIndex(
        uint _index,
        address _add
    )
        external
        view
        returns(
            uint status,
            uint coverid,
            uint claimId
        )
    {
        claimId = allClaimsByAddress[_add][_index];
        status = claimsStatus[claimId];
        coverid = allClaims[claimId].coverId;
    }

    /**
     * @dev Gets Id of all the votes given to a claim.
     * @param _claimId Claim Id.
     * @return ca id of all the votes given by Claim assessors to a claim.
     * @return mv id of all the votes given by members to a claim.
     */ 
    function getAllVotesForClaim(
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint[] memory ca,
            uint[] memory mv
        )
    {
        return (_claimId, claimVoteCA[_claimId], claimVoteMember[_claimId]);
    }

    /** 
     * @dev Gets Number of tokens deposit in a vote using
     * Claim assessor's address and claim id.
     * @return tokens Number of deposited tokens.
     */ 
    function getTokensClaim(
        address _of,
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint tokens
        )
    {
        return (_claimId, allvotes[userClaimVoteCA[_of][_claimId]].tokens);
    }

    /**
     * @param _voter address of the voter.
     * @return lastCAvoteIndex last index till which reward was distributed for CA
     * @return lastMVvoteIndex last index till which reward was distributed for member
     */ 
    function getRewardDistributedIndex(
        address _voter
    ) 
        external
        view
        returns(
            uint lastCAvoteIndex,
            uint lastMVvoteIndex
        )
    {
        return (
            voterVoteRewardReceived[_voter].lastCAvoteIndex,
            voterVoteRewardReceived[_voter].lastMVvoteIndex
        );
    }

    /**
     * @param claimid claim id.
     * @return perc_CA reward Percentage for claim assessor
     * @return perc_MV reward Percentage for members
     * @return tokens total tokens to be rewarded 
     */ 
    function getClaimRewardDetail(
        uint claimid
    ) 
        external
        view
        returns(
            uint percCA,
            uint percMV,
            uint tokens
        )
    {
        return (
            claimRewardDetail[claimid].percCA,
            claimRewardDetail[claimid].percMV,
            claimRewardDetail[claimid].tokenToBeDist
        );
    }

    /**
     * @dev Gets cover id of a claim.
     */ 
    function getClaimCoverId(uint _claimId) external view returns(uint claimId, uint coverid) {
        return (_claimId, allClaims[_claimId].coverId);
    }

    /**
     * @dev Gets total number of tokens staked during voting by Claim Assessors.
     * @param _claimId Claim Id.
     * @param _verdict 1 to get total number of accept tokens, -1 to get total number of deny tokens.
     * @return token token Number of tokens(either accept or deny on the basis of verdict given as parameter).
     */ 
    function getClaimVote(uint _claimId, int8 _verdict) external view returns(uint claimId, uint token) {
        claimId = _claimId;
        token = 0;
        for (uint i = 0; i < claimVoteCA[_claimId].length; i++) {
            if (allvotes[claimVoteCA[_claimId][i]].verdict == _verdict)
                token = token.add(allvotes[claimVoteCA[_claimId][i]].tokens);
        }
    }

    /**
     * @dev Gets total number of tokens staked during voting by Members.
     * @param _claimId Claim Id.
     * @param _verdict 1 to get total number of accept tokens,
     *  -1 to get total number of deny tokens.
     * @return token token Number of tokens(either accept or 
     * deny on the basis of verdict given as parameter).
     */ 
    function getClaimMVote(uint _claimId, int8 _verdict) external view returns(uint claimId, uint token) {
        claimId = _claimId;
        token = 0;
        for (uint i = 0; i < claimVoteMember[_claimId].length; i++) {
            if (allvotes[claimVoteMember[_claimId][i]].verdict == _verdict)
                token = token.add(allvotes[claimVoteMember[_claimId][i]].tokens);
        }
    }

    /**
     * @param _voter address  of voteid
     * @param index index to get voteid in CA
     */ 
    function getVoteAddressCA(address _voter, uint index) external view returns(uint) {
        return voteAddressCA[_voter][index];
    }

    /**
     * @param _voter address  of voter
     * @param index index to get voteid in member vote
     */ 
    function getVoteAddressMember(address _voter, uint index) external view returns(uint) {
        return voteAddressMember[_voter][index];
    }

    /**
     * @param _voter address  of voter   
     */ 
    function getVoteAddressCALength(address _voter) external view returns(uint) {
        return voteAddressCA[_voter].length;
    }

    /**
     * @param _voter address  of voter   
     */ 
    function getVoteAddressMemberLength(address _voter) external view returns(uint) {
        return voteAddressMember[_voter].length;
    }

    /**
     * @dev Gets the Final result of voting of a claim.
     * @param _claimId Claim id.
     * @return verdict 1 if claim is accepted, -1 if declined.
     */ 
    function getFinalVerdict(uint _claimId) external view returns(int8 verdict) {
        return claimVote[_claimId];
    }

    /**
     * @dev Get number of Claims queued for submission during emergency pause.
     */ 
    function getLengthOfClaimSubmittedAtEP() external view returns(uint len) {
        len = claimPause.length;
    }

    /**
     * @dev Gets the index from which claim needs to be 
     * submitted when emergency pause is swithched off.
     */ 
    function getFirstClaimIndexToSubmitAfterEP() external view returns(uint indexToSubmit) {
        indexToSubmit = claimPauseLastsubmit;
    }
    
    /**
     * @dev Gets number of Claims to be reopened for voting post emergency pause period.
     */ 
    function getLengthOfClaimVotingPause() external view returns(uint len) {
        len = claimPauseVotingEP.length;
    }

    /**
     * @dev Gets claim details to be reopened for voting after emergency pause.
     */ 
    function getPendingClaimDetailsByIndex(
        uint _index
    )
        external
        view
        returns(
            uint claimId,
            uint pendingTime,
            bool voting
        )
    {
        claimId = claimPauseVotingEP[_index].claimid;
        pendingTime = claimPauseVotingEP[_index].pendingTime;
        voting = claimPauseVotingEP[_index].voting;
    }

    /** 
     * @dev Gets the index from which claim needs to be reopened when emergency pause is swithched off.
     */ 
    function getFirstClaimIndexToStartVotingAfterEP() external view returns(uint firstindex) {
        firstindex = claimStartVotingFirstIndex;
    }

    /**
     * @dev Updates Uint Parameters of a code
     * @param code whose details we want to update
     * @param val value to set
     */
    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "CAMAXVT") {
            _setMaxVotingTime(val * 1 hours);

        } else if (code == "CAMINVT") {

            _setMinVotingTime(val * 1 hours);

        } else if (code == "CAPRETRY") {

            _setPayoutRetryTime(val * 1 hours);

        } else if (code == "CADEPT") {

            _setClaimDepositTime(val * 1 days);

        } else if (code == "CAREWPER") {

            _setClaimRewardPerc(val);

        } else if (code == "CAMINTH") {

            _setMinVoteThreshold(val);

        } else if (code == "CAMAXTH") {

            _setMaxVoteThreshold(val);

        } else if (code == "CACONPER") {

            _setMajorityConsensus(val);

        } else if (code == "CAPAUSET") {
            _setPauseDaysCA(val * 1 days);
        } else {

            revert("Invalid param code");
        }
    
    }

    /**
     * @dev Iupgradable Interface to update dependent contract address
     */
    function changeDependentContractAddress() public onlyInternal {}

    /**
     * @dev Adds status under which a claim can lie.
     * @param percCA reward percentage for claim assessor
     * @param percMV reward percentage for members
     */
    function _pushStatus(uint percCA, uint percMV) internal {
        rewardStatus.push(ClaimRewardStatus(percCA, percMV));
    }

    /**
     * @dev adds reward incentive for all possible claim status for Claim assessors and members
     */
    function _addRewardIncentive() internal {
        _pushStatus(0, 0); //0  Pending-Claim Assessor Vote
        _pushStatus(0, 0); //1 Pending-Claim Assessor Vote Denied, Pending Member Vote
        _pushStatus(0, 0); //2 Pending-CA Vote Threshold not Reached Accept, Pending Member Vote
        _pushStatus(0, 0); //3 Pending-CA Vote Threshold not Reached Deny, Pending Member Vote
        _pushStatus(0, 0); //4 Pending-CA Consensus not reached Accept, Pending Member Vote
        _pushStatus(0, 0); //5 Pending-CA Consensus not reached Deny, Pending Member Vote
        _pushStatus(100, 0); //6 Final-Claim Assessor Vote Denied
        _pushStatus(100, 0); //7 Final-Claim Assessor Vote Accepted
        _pushStatus(0, 100); //8 Final-Claim Assessor Vote Denied, MV Accepted
        _pushStatus(0, 100); //9 Final-Claim Assessor Vote Denied, MV Denied
        _pushStatus(0, 0); //10 Final-Claim Assessor Vote Accept, MV Nodecision
        _pushStatus(0, 0); //11 Final-Claim Assessor Vote Denied, MV Nodecision
        _pushStatus(0, 0); //12 Claim Accepted Payout Pending
        _pushStatus(0, 0); //13 Claim Accepted No Payout 
        _pushStatus(0, 0); //14 Claim Accepted Payout Done
    }

    /**
     * @dev Sets Maximum time(in seconds) for which claim assessment voting is open
     */ 
    function _setMaxVotingTime(uint _time) internal {
        maxVotingTime = _time;
    }

    /**
     *  @dev Sets Minimum time(in seconds) for which claim assessment voting is open
     */ 
    function _setMinVotingTime(uint _time) internal {
        minVotingTime = _time;
    }

    /**
     *  @dev Sets Minimum vote threshold required
     */ 
    function _setMinVoteThreshold(uint val) internal {
        minVoteThreshold = val;
    }

    /**
     *  @dev Sets Maximum vote threshold required
     */ 
    function _setMaxVoteThreshold(uint val) internal {
        maxVoteThreshold = val;
    }
    
    /**
     *  @dev Sets the value considered as Majority Consenus in voting
     */ 
    function _setMajorityConsensus(uint val) internal {
        majorityConsensus = val;
    }

    /**
     * @dev Sets the payout retry time
     */ 
    function _setPayoutRetryTime(uint _time) internal {
        payoutRetryTime = _time;
    }

    /**
     *  @dev Sets percentage of reward given for claim assessment
     */ 
    function _setClaimRewardPerc(uint _val) internal {

        claimRewardPerc = _val;
    }
  
    /** 
     * @dev Sets the time for which claim is deposited.
     */ 
    function _setClaimDepositTime(uint _time) internal {

        claimDepositTime = _time;
    }

    /**
     *  @dev Sets number of days claim assessment will be paused
     */ 
    function _setPauseDaysCA(uint val) internal {
        pauseDaysCA = val;
    }
}

// File: nexusmutual-contracts/contracts/PoolData.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;




contract DSValue {
    function peek() public view returns (bytes32, bool);
    function read() public view returns (bytes32);
}


contract PoolData is Iupgradable {
    using SafeMath for uint;

    struct ApiId {
        bytes4 typeOf;
        bytes4 currency;
        uint id;
        uint64 dateAdd;
        uint64 dateUpd;
    }

    struct CurrencyAssets {
        address currAddress;
        uint baseMin;
        uint varMin;
    }

    struct InvestmentAssets {
        address currAddress;
        bool status;
        uint64 minHoldingPercX100;
        uint64 maxHoldingPercX100;
        uint8 decimals;
    }

    struct IARankDetails {
        bytes4 maxIACurr;
        uint64 maxRate;
        bytes4 minIACurr;
        uint64 minRate;
    }

    struct McrData {
        uint mcrPercx100;
        uint mcrEther;
        uint vFull; //Pool funds
        uint64 date;
    }

    IARankDetails[] internal allIARankDetails;
    McrData[] public allMCRData;

    bytes4[] internal allInvestmentCurrencies;
    bytes4[] internal allCurrencies;
    bytes32[] public allAPIcall;
    mapping(bytes32 => ApiId) public allAPIid;
    mapping(uint64 => uint) internal datewiseId;
    mapping(bytes16 => uint) internal currencyLastIndex;
    mapping(bytes4 => CurrencyAssets) internal allCurrencyAssets;
    mapping(bytes4 => InvestmentAssets) internal allInvestmentAssets;
    mapping(bytes4 => uint) internal caAvgRate;
    mapping(bytes4 => uint) internal iaAvgRate;

    address public notariseMCR;
    address public daiFeedAddress;
    uint private constant DECIMAL1E18 = uint(10) ** 18;
    uint public uniswapDeadline;
    uint public liquidityTradeCallbackTime;
    uint public lastLiquidityTradeTrigger;
    uint64 internal lastDate;
    uint public variationPercX100;
    uint public iaRatesTime;
    uint public minCap;
    uint public mcrTime;
    uint public a;
    uint public shockParameter;
    uint public c;
    uint public mcrFailTime; 
    uint public ethVolumeLimit;
    uint public capReached;
    uint public capacityLimit;
    
    constructor(address _notariseAdd, address _daiFeedAdd, address _daiAdd) public {
        notariseMCR = _notariseAdd;
        daiFeedAddress = _daiFeedAdd;
        c = 5800000;
        a = 1028;
        mcrTime = 24 hours;
        mcrFailTime = 6 hours;
        allMCRData.push(McrData(0, 0, 0, 0));
        minCap = 12000 * DECIMAL1E18;
        shockParameter = 50;
        variationPercX100 = 100; //1%
        iaRatesTime = 24 hours; //24 hours in seconds
        uniswapDeadline = 20 minutes;
        liquidityTradeCallbackTime = 4 hours;
        ethVolumeLimit = 4;
        capacityLimit = 10;
        allCurrencies.push("ETH");
        allCurrencyAssets["ETH"] = CurrencyAssets(address(0), 1000 * DECIMAL1E18, 0);
        allCurrencies.push("DAI");
        allCurrencyAssets["DAI"] = CurrencyAssets(_daiAdd, 50000 * DECIMAL1E18, 0);
        allInvestmentCurrencies.push("ETH");
        allInvestmentAssets["ETH"] = InvestmentAssets(address(0), true, 2500, 10000, 18);
        allInvestmentCurrencies.push("DAI");
        allInvestmentAssets["DAI"] = InvestmentAssets(_daiAdd, true, 250, 1500, 18);
    }

    /**
     * @dev to set the maximum cap allowed 
     * @param val is the new value
     */
    function setCapReached(uint val) external onlyInternal {
        capReached = val;
    }
    
    /// @dev Updates the 3 day average rate of a IA currency.
    /// To be replaced by MakerDao's on chain rates
    /// @param curr IA Currency Name.
    /// @param rate Average exchange rate X 100 (of last 3 days).
    function updateIAAvgRate(bytes4 curr, uint rate) external onlyInternal {
        iaAvgRate[curr] = rate;
    }

    /// @dev Updates the 3 day average rate of a CA currency.
    /// To be replaced by MakerDao's on chain rates
    /// @param curr Currency Name.
    /// @param rate Average exchange rate X 100 (of last 3 days).
    function updateCAAvgRate(bytes4 curr, uint rate) external onlyInternal {
        caAvgRate[curr] = rate;
    }

    /// @dev Adds details of (Minimum Capital Requirement)MCR.
    /// @param mcrp Minimum Capital Requirement percentage (MCR% * 100 ,Ex:for 54.56% ,given 5456)
    /// @param vf Pool fund value in Ether used in the last full daily calculation from the Capital model.
    function pushMCRData(uint mcrp, uint mcre, uint vf, uint64 time) external onlyInternal {
        allMCRData.push(McrData(mcrp, mcre, vf, time));
    }

    /** 
     * @dev Updates the Timestamp at which result of oracalize call is received.
     */  
    function updateDateUpdOfAPI(bytes32 myid) external onlyInternal {
        allAPIid[myid].dateUpd = uint64(now);
    }

    /** 
     * @dev Saves the details of the Oraclize API.
     * @param myid Id return by the oraclize query.
     * @param _typeof type of the query for which oraclize call is made.
     * @param id ID of the proposal,quote,cover etc. for which oraclize call is made 
     */  
    function saveApiDetails(bytes32 myid, bytes4 _typeof, uint id) external onlyInternal {
        allAPIid[myid] = ApiId(_typeof, "", id, uint64(now), uint64(now));
    }

    /** 
     * @dev Stores the id return by the oraclize query. 
     * Maintains record of all the Ids return by oraclize query.
     * @param myid Id return by the oraclize query.
     */  
    function addInAllApiCall(bytes32 myid) external onlyInternal {
        allAPIcall.push(myid);
    }
    
    /**
     * @dev Saves investment asset rank details.
     * @param maxIACurr Maximum ranked investment asset currency.
     * @param maxRate Maximum ranked investment asset rate.
     * @param minIACurr Minimum ranked investment asset currency.
     * @param minRate Minimum ranked investment asset rate.
     * @param date in yyyymmdd.
     */  
    function saveIARankDetails(
        bytes4 maxIACurr,
        uint64 maxRate,
        bytes4 minIACurr,
        uint64 minRate,
        uint64 date
    )
        external
        onlyInternal
    {
        allIARankDetails.push(IARankDetails(maxIACurr, maxRate, minIACurr, minRate));
        datewiseId[date] = allIARankDetails.length.sub(1);
    }

    /**
     * @dev to get the time for the laste liquidity trade trigger
     */
    function setLastLiquidityTradeTrigger() external onlyInternal {
        lastLiquidityTradeTrigger = now;
    }

    /** 
     * @dev Updates Last Date.
     */  
    function updatelastDate(uint64 newDate) external onlyInternal {
        lastDate = newDate;
    }

    /**
     * @dev Adds currency asset currency. 
     * @param curr currency of the asset
     * @param currAddress address of the currency
     * @param baseMin base minimum in 10^18. 
     */  
    function addCurrencyAssetCurrency(
        bytes4 curr,
        address currAddress,
        uint baseMin
    ) 
        external
    {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allCurrencies.push(curr);
        allCurrencyAssets[curr] = CurrencyAssets(currAddress, baseMin, 0);
    }
    
    /**
     * @dev Adds investment asset. 
     */  
    function addInvestmentAssetCurrency(
        bytes4 curr,
        address currAddress,
        bool status,
        uint64 minHoldingPercX100,
        uint64 maxHoldingPercX100,
        uint8 decimals
    ) 
        external
    {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allInvestmentCurrencies.push(curr);
        allInvestmentAssets[curr] = InvestmentAssets(currAddress, status,
            minHoldingPercX100, maxHoldingPercX100, decimals);
    }

    /**
     * @dev Changes base minimum of a given currency asset.
     */ 
    function changeCurrencyAssetBaseMin(bytes4 curr, uint baseMin) external {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allCurrencyAssets[curr].baseMin = baseMin;
    }

    /**
     * @dev changes variable minimum of a given currency asset.
     */  
    function changeCurrencyAssetVarMin(bytes4 curr, uint varMin) external onlyInternal {
        allCurrencyAssets[curr].varMin = varMin;
    }

    /** 
     * @dev Changes the investment asset status.
     */ 
    function changeInvestmentAssetStatus(bytes4 curr, bool status) external {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allInvestmentAssets[curr].status = status;
    }

    /** 
     * @dev Changes the investment asset Holding percentage of a given currency.
     */
    function changeInvestmentAssetHoldingPerc(
        bytes4 curr,
        uint64 minPercX100,
        uint64 maxPercX100
    )
        external
    {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allInvestmentAssets[curr].minHoldingPercX100 = minPercX100;
        allInvestmentAssets[curr].maxHoldingPercX100 = maxPercX100;
    }

    /**
     * @dev Gets Currency asset token address. 
     */  
    function changeCurrencyAssetAddress(bytes4 curr, address currAdd) external {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allCurrencyAssets[curr].currAddress = currAdd;
    }

    /**
     * @dev Changes Investment asset token address.
     */ 
    function changeInvestmentAssetAddressAndDecimal(
        bytes4 curr,
        address currAdd,
        uint8 newDecimal
    )
        external
    {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allInvestmentAssets[curr].currAddress = currAdd;
        allInvestmentAssets[curr].decimals = newDecimal;
    }

    /// @dev Changes address allowed to post MCR.
    function changeNotariseAddress(address _add) external onlyInternal {
        notariseMCR = _add;
    }

    /// @dev updates daiFeedAddress address.
    /// @param _add address of DAI feed.
    function changeDAIfeedAddress(address _add) external onlyInternal {
        daiFeedAddress = _add;
    }

    /**
     * @dev Gets Uint Parameters of a code
     * @param code whose details we want
     * @return string value of the code
     * @return associated amount (time or perc or value) to the code
     */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {
        codeVal = code;
        if (code == "MCRTIM") {
            val = mcrTime / (1 hours);

        } else if (code == "MCRFTIM") {

            val = mcrFailTime / (1 hours);

        } else if (code == "MCRMIN") {

            val = minCap;

        } else if (code == "MCRSHOCK") {

            val = shockParameter;

        } else if (code == "MCRCAPL") {

            val = capacityLimit;

        } else if (code == "IMZ") {

            val = variationPercX100;

        } else if (code == "IMRATET") {

            val = iaRatesTime / (1 hours);

        } else if (code == "IMUNIDL") {

            val = uniswapDeadline / (1 minutes);

        } else if (code == "IMLIQT") {

            val = liquidityTradeCallbackTime / (1 hours);

        } else if (code == "IMETHVL") {

            val = ethVolumeLimit;

        } else if (code == "C") {
            val = c;

        } else if (code == "A") {

            val = a;

        }
            
    }
 
    /// @dev Checks whether a given address can notaise MCR data or not.
    /// @param _add Address.
    /// @return res Returns 0 if address is not authorized, else 1.
    function isnotarise(address _add) external view returns(bool res) {
        res = false;
        if (_add == notariseMCR)
            res = true;
    }

    /// @dev Gets the details of last added MCR.
    /// @return mcrPercx100 Total Minimum Capital Requirement percentage of that month of year(multiplied by 100).
    /// @return vFull Total Pool fund value in Ether used in the last full daily calculation.
    function getLastMCR() external view returns(uint mcrPercx100, uint mcrEtherx1E18, uint vFull, uint64 date) {
        uint index = allMCRData.length.sub(1);
        return (
            allMCRData[index].mcrPercx100,
            allMCRData[index].mcrEther,
            allMCRData[index].vFull,
            allMCRData[index].date
        );
    }

    /// @dev Gets last Minimum Capital Requirement percentage of Capital Model
    /// @return val MCR% value,multiplied by 100.
    function getLastMCRPerc() external view returns(uint) {
        return allMCRData[allMCRData.length.sub(1)].mcrPercx100;
    }

    /// @dev Gets last Ether price of Capital Model
    /// @return val ether value,multiplied by 100.
    function getLastMCREther() external view returns(uint) {
        return allMCRData[allMCRData.length.sub(1)].mcrEther;
    }

    /// @dev Gets Pool fund value in Ether used in the last full daily calculation from the Capital model.
    function getLastVfull() external view returns(uint) {
        return allMCRData[allMCRData.length.sub(1)].vFull;
    }

    /// @dev Gets last Minimum Capital Requirement in Ether.
    /// @return date of MCR.
    function getLastMCRDate() external view returns(uint64 date) {
        date = allMCRData[allMCRData.length.sub(1)].date;
    }

    /// @dev Gets details for token price calculation.
    function getTokenPriceDetails(bytes4 curr) external view returns(uint _a, uint _c, uint rate) {
        _a = a;
        _c = c;
        rate = _getAvgRate(curr, false);
    }
    
    /// @dev Gets the total number of times MCR calculation has been made.
    function getMCRDataLength() external view returns(uint len) {
        len = allMCRData.length;
    }
 
    /**
     * @dev Gets investment asset rank details by given date.
     */  
    function getIARankDetailsByDate(
        uint64 date
    )
        external
        view
        returns(
            bytes4 maxIACurr,
            uint64 maxRate,
            bytes4 minIACurr,
            uint64 minRate
        )
    {
        uint index = datewiseId[date];
        return (
            allIARankDetails[index].maxIACurr,
            allIARankDetails[index].maxRate,
            allIARankDetails[index].minIACurr,
            allIARankDetails[index].minRate
        );
    }

    /** 
     * @dev Gets Last Date.
     */ 
    function getLastDate() external view returns(uint64 date) {
        return lastDate;
    }

    /**
     * @dev Gets investment currency for a given index.
     */  
    function getInvestmentCurrencyByIndex(uint index) external view returns(bytes4 currName) {
        return allInvestmentCurrencies[index];
    }

    /**
     * @dev Gets count of investment currency.
     */  
    function getInvestmentCurrencyLen() external view returns(uint len) {
        return allInvestmentCurrencies.length;
    }

    /**
     * @dev Gets all the investment currencies.
     */ 
    function getAllInvestmentCurrencies() external view returns(bytes4[] memory currencies) {
        return allInvestmentCurrencies;
    }

    /**
     * @dev Gets All currency for a given index.
     */  
    function getCurrenciesByIndex(uint index) external view returns(bytes4 currName) {
        return allCurrencies[index];
    }

    /** 
     * @dev Gets count of All currency.
     */  
    function getAllCurrenciesLen() external view returns(uint len) {
        return allCurrencies.length;
    }

    /**
     * @dev Gets all currencies 
     */  
    function getAllCurrencies() external view returns(bytes4[] memory currencies) {
        return allCurrencies;
    }

    /**
     * @dev Gets currency asset details for a given currency.
     */  
    function getCurrencyAssetVarBase(
        bytes4 curr
    )
        external
        view
        returns(
            bytes4 currency,
            uint baseMin,
            uint varMin
        )
    {
        return (
            curr,
            allCurrencyAssets[curr].baseMin,
            allCurrencyAssets[curr].varMin
        );
    }

    /**
     * @dev Gets minimum variable value for currency asset.
     */  
    function getCurrencyAssetVarMin(bytes4 curr) external view returns(uint varMin) {
        return allCurrencyAssets[curr].varMin;
    }

    /** 
     * @dev Gets base minimum of  a given currency asset.
     */  
    function getCurrencyAssetBaseMin(bytes4 curr) external view returns(uint baseMin) {
        return allCurrencyAssets[curr].baseMin;
    }

    /** 
     * @dev Gets investment asset maximum and minimum holding percentage of a given currency.
     */  
    function getInvestmentAssetHoldingPerc(
        bytes4 curr
    )
        external
        view
        returns(
            uint64 minHoldingPercX100,
            uint64 maxHoldingPercX100
        )
    {
        return (
            allInvestmentAssets[curr].minHoldingPercX100,
            allInvestmentAssets[curr].maxHoldingPercX100
        );
    }

    /** 
     * @dev Gets investment asset decimals.
     */  
    function getInvestmentAssetDecimals(bytes4 curr) external view returns(uint8 decimal) {
        return allInvestmentAssets[curr].decimals;
    }

    /**
     * @dev Gets investment asset maximum holding percentage of a given currency.
     */  
    function getInvestmentAssetMaxHoldingPerc(bytes4 curr) external view returns(uint64 maxHoldingPercX100) {
        return allInvestmentAssets[curr].maxHoldingPercX100;
    }

    /**
     * @dev Gets investment asset minimum holding percentage of a given currency.
     */  
    function getInvestmentAssetMinHoldingPerc(bytes4 curr) external view returns(uint64 minHoldingPercX100) {
        return allInvestmentAssets[curr].minHoldingPercX100;
    }

    /** 
     * @dev Gets investment asset details of a given currency
     */  
    function getInvestmentAssetDetails(
        bytes4 curr
    )
        external
        view
        returns(
            bytes4 currency,
            address currAddress,
            bool status,
            uint64 minHoldingPerc,
            uint64 maxHoldingPerc,
            uint8 decimals
        )
    {
        return (
            curr,
            allInvestmentAssets[curr].currAddress,
            allInvestmentAssets[curr].status,
            allInvestmentAssets[curr].minHoldingPercX100,
            allInvestmentAssets[curr].maxHoldingPercX100,
            allInvestmentAssets[curr].decimals
        );
    }

    /**
     * @dev Gets Currency asset token address.
     */  
    function getCurrencyAssetAddress(bytes4 curr) external view returns(address) {
        return allCurrencyAssets[curr].currAddress;
    }

    /**
     * @dev Gets investment asset token address.
     */  
    function getInvestmentAssetAddress(bytes4 curr) external view returns(address) {
        return allInvestmentAssets[curr].currAddress;
    }

    /**
     * @dev Gets investment asset active Status of a given currency.
     */  
    function getInvestmentAssetStatus(bytes4 curr) external view returns(bool status) {
        return allInvestmentAssets[curr].status;
    }

    /** 
     * @dev Gets type of oraclize query for a given Oraclize Query ID.
     * @param myid Oraclize Query ID identifying the query for which the result is being received.
     * @return _typeof It could be of type "quote","quotation","cover","claim" etc.
     */  
    function getApiIdTypeOf(bytes32 myid) external view returns(bytes4) {
        return allAPIid[myid].typeOf;
    }

    /** 
     * @dev Gets ID associated to oraclize query for a given Oraclize Query ID.
     * @param myid Oraclize Query ID identifying the query for which the result is being received.
     * @return id1 It could be the ID of "proposal","quotation","cover","claim" etc.
     */  
    function getIdOfApiId(bytes32 myid) external view returns(uint) {
        return allAPIid[myid].id;
    }

    /** 
     * @dev Gets the Timestamp of a oracalize call.
     */  
    function getDateAddOfAPI(bytes32 myid) external view returns(uint64) {
        return allAPIid[myid].dateAdd;
    }

    /**
     * @dev Gets the Timestamp at which result of oracalize call is received.
     */  
    function getDateUpdOfAPI(bytes32 myid) external view returns(uint64) {
        return allAPIid[myid].dateUpd;
    }

    /** 
     * @dev Gets currency by oracalize id. 
     */  
    function getCurrOfApiId(bytes32 myid) external view returns(bytes4) {
        return allAPIid[myid].currency;
    }

    /**
     * @dev Gets ID return by the oraclize query of a given index.
     * @param index Index.
     * @return myid ID return by the oraclize query.
     */  
    function getApiCallIndex(uint index) external view returns(bytes32 myid) {
        myid = allAPIcall[index];
    }

    /**
     * @dev Gets Length of API call. 
     */  
    function getApilCallLength() external view returns(uint) {
        return allAPIcall.length;
    }
    
    /**
     * @dev Get Details of Oraclize API when given Oraclize Id.
     * @param myid ID return by the oraclize query.
     * @return _typeof ype of the query for which oraclize 
     * call is made.("proposal","quote","quotation" etc.) 
     */  
    function getApiCallDetails(
        bytes32 myid
    )
        external
        view
        returns(
            bytes4 _typeof,
            bytes4 curr,
            uint id,
            uint64 dateAdd,
            uint64 dateUpd
        )
    {
        return (
            allAPIid[myid].typeOf,
            allAPIid[myid].currency,
            allAPIid[myid].id,
            allAPIid[myid].dateAdd,
            allAPIid[myid].dateUpd
        );
    }

    /**
     * @dev Updates Uint Parameters of a code
     * @param code whose details we want to update
     * @param val value to set
     */
    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "MCRTIM") {
            _changeMCRTime(val * 1 hours);

        } else if (code == "MCRFTIM") {

            _changeMCRFailTime(val * 1 hours);

        } else if (code == "MCRMIN") {

            _changeMinCap(val);

        } else if (code == "MCRSHOCK") {

            _changeShockParameter(val);

        } else if (code == "MCRCAPL") {

            _changeCapacityLimit(val);

        } else if (code == "IMZ") {

            _changeVariationPercX100(val);

        } else if (code == "IMRATET") {

            _changeIARatesTime(val * 1 hours);

        } else if (code == "IMUNIDL") {

            _changeUniswapDeadlineTime(val * 1 minutes);

        } else if (code == "IMLIQT") {

            _changeliquidityTradeCallbackTime(val * 1 hours);

        } else if (code == "IMETHVL") {

            _setEthVolumeLimit(val);

        } else if (code == "C") {
            _changeC(val);

        } else if (code == "A") {

            _changeA(val);

        } else {
            revert("Invalid param code");
        }
            
    }

    /**
     * @dev to get the average rate of currency rate 
     * @param curr is the currency in concern
     * @return required rate
     */
    function getCAAvgRate(bytes4 curr) public view returns(uint rate) {
        return _getAvgRate(curr, false);
    }

    /**
     * @dev to get the average rate of investment rate 
     * @param curr is the investment in concern
     * @return required rate
     */
    function getIAAvgRate(bytes4 curr) public view returns(uint rate) {
        return _getAvgRate(curr, true);
    }

    function changeDependentContractAddress() public onlyInternal {}

    /// @dev Gets the average rate of a CA currency.
    /// @param curr Currency Name.
    /// @return rate Average rate X 100(of last 3 days).
    function _getAvgRate(bytes4 curr, bool isIA) internal view returns(uint rate) {
        if (curr == "DAI") {
            DSValue ds = DSValue(daiFeedAddress);
            rate = uint(ds.read()).div(uint(10) ** 16);
        } else if (isIA) {
            rate = iaAvgRate[curr];
        } else {
            rate = caAvgRate[curr];
        }
    }

    /**
     * @dev to set the ethereum volume limit 
     * @param val is the new limit value
     */
    function _setEthVolumeLimit(uint val) internal {
        ethVolumeLimit = val;
    }

    /// @dev Sets minimum Cap.
    function _changeMinCap(uint newCap) internal {
        minCap = newCap;
    }

    /// @dev Sets Shock Parameter.
    function _changeShockParameter(uint newParam) internal {
        shockParameter = newParam;
    }
    
    /// @dev Changes time period for obtaining new MCR data from external oracle query.
    function _changeMCRTime(uint _time) internal {
        mcrTime = _time;
    }

    /// @dev Sets MCR Fail time.
    function _changeMCRFailTime(uint _time) internal {
        mcrFailTime = _time;
    }

    /**
     * @dev to change the uniswap deadline time 
     * @param newDeadline is the value
     */
    function _changeUniswapDeadlineTime(uint newDeadline) internal {
        uniswapDeadline = newDeadline;
    }

    /**
     * @dev to change the liquidity trade call back time 
     * @param newTime is the new value to be set
     */
    function _changeliquidityTradeCallbackTime(uint newTime) internal {
        liquidityTradeCallbackTime = newTime;
    }

    /**
     * @dev Changes time after which investment asset rates need to be fed.
     */  
    function _changeIARatesTime(uint _newTime) internal {
        iaRatesTime = _newTime;
    }
    
    /**
     * @dev Changes the variation range percentage.
     */  
    function _changeVariationPercX100(uint newPercX100) internal {
        variationPercX100 = newPercX100;
    }

    /// @dev Changes Growth Step
    function _changeC(uint newC) internal {
        c = newC;
    }

    /// @dev Changes scaling factor.
    function _changeA(uint val) internal {
        a = val;
    }
    
    /**
     * @dev to change the capacity limit 
     * @param val is the new value
     */
    function _changeCapacityLimit(uint val) internal {
        capacityLimit = val;
    }    
}

// File: nexusmutual-contracts/contracts/QuotationData.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;




contract QuotationData is Iupgradable {
    using SafeMath for uint;

    enum HCIDStatus { NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover }

    enum CoverStatus { Active, ClaimAccepted, ClaimDenied, CoverExpired, ClaimSubmitted, Requested }

    struct Cover {
        address payable memberAddress;
        bytes4 currencyCode;
        uint sumAssured;
        uint16 coverPeriod;
        uint validUntil;
        address scAddress;
        uint premiumNXM;
    }

    struct HoldCover {
        uint holdCoverId;
        address payable userAddress;
        address scAddress;
        bytes4 coverCurr;
        uint[] coverDetails;
        uint16 coverPeriod;
    }

    address public authQuoteEngine;
  
    mapping(bytes4 => uint) internal currencyCSA;
    mapping(address => uint[]) internal userCover;
    mapping(address => uint[]) public userHoldedCover;
    mapping(address => bool) public refundEligible;
    mapping(address => mapping(bytes4 => uint)) internal currencyCSAOfSCAdd;
    mapping(uint => uint8) public coverStatus;
    mapping(uint => uint) public holdedCoverIDStatus;
    mapping(uint => bool) public timestampRepeated; 
    

    Cover[] internal allCovers;
    HoldCover[] internal allCoverHolded;

    uint public stlp;
    uint public stl;
    uint public pm;
    uint public minDays;
    uint public tokensRetained;
    address public kycAuthAddress;

    event CoverDetailsEvent(
        uint indexed cid,
        address scAdd,
        uint sumAssured,
        uint expiry,
        uint premium,
        uint premiumNXM,
        bytes4 curr
    );

    event CoverStatusEvent(uint indexed cid, uint8 statusNum);

    constructor(address _authQuoteAdd, address _kycAuthAdd) public {
        authQuoteEngine = _authQuoteAdd;
        kycAuthAddress = _kycAuthAdd;
        stlp = 90;
        stl = 100;
        pm = 30;
        minDays = 30;
        tokensRetained = 10;
        allCovers.push(Cover(address(0), "0x00", 0, 0, 0, address(0), 0));
        uint[] memory arr = new uint[](1);
        allCoverHolded.push(HoldCover(0, address(0), address(0), 0x00, arr, 0));

    }
    
    /// @dev Adds the amount in Total Sum Assured of a given currency of a given smart contract address.
    /// @param _add Smart Contract Address.
    /// @param _amount Amount to be added.
    function addInTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external onlyInternal {
        currencyCSAOfSCAdd[_add][_curr] = currencyCSAOfSCAdd[_add][_curr].add(_amount);
    }

    /// @dev Subtracts the amount from Total Sum Assured of a given currency and smart contract address.
    /// @param _add Smart Contract Address.
    /// @param _amount Amount to be subtracted.
    function subFromTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external onlyInternal {
        currencyCSAOfSCAdd[_add][_curr] = currencyCSAOfSCAdd[_add][_curr].sub(_amount);
    }
    
    /// @dev Subtracts the amount from Total Sum Assured of a given currency.
    /// @param _curr Currency Name.
    /// @param _amount Amount to be subtracted.
    function subFromTotalSumAssured(bytes4 _curr, uint _amount) external onlyInternal {
        currencyCSA[_curr] = currencyCSA[_curr].sub(_amount);
    }

    /// @dev Adds the amount in Total Sum Assured of a given currency.
    /// @param _curr Currency Name.
    /// @param _amount Amount to be added.
    function addInTotalSumAssured(bytes4 _curr, uint _amount) external onlyInternal {
        currencyCSA[_curr] = currencyCSA[_curr].add(_amount);
    }

    /// @dev sets bit for timestamp to avoid replay attacks.
    function setTimestampRepeated(uint _timestamp) external onlyInternal {
        timestampRepeated[_timestamp] = true;
    }
    
    /// @dev Creates a blank new cover.
    function addCover(
        uint16 _coverPeriod,
        uint _sumAssured,
        address payable _userAddress,
        bytes4 _currencyCode,
        address _scAddress,
        uint premium,
        uint premiumNXM
    )   
        external
        onlyInternal
    {
        uint expiryDate = now.add(uint(_coverPeriod).mul(1 days));
        allCovers.push(Cover(_userAddress, _currencyCode,
                _sumAssured, _coverPeriod, expiryDate, _scAddress, premiumNXM));
        uint cid = allCovers.length.sub(1);
        userCover[_userAddress].push(cid);
        emit CoverDetailsEvent(cid, _scAddress, _sumAssured, expiryDate, premium, premiumNXM, _currencyCode);
    }

    /// @dev create holded cover which will process after verdict of KYC.
    function addHoldCover(
        address payable from,
        address scAddress,
        bytes4 coverCurr, 
        uint[] calldata coverDetails,
        uint16 coverPeriod
    )   
        external
        onlyInternal
    {
        uint holdedCoverLen = allCoverHolded.length;
        holdedCoverIDStatus[holdedCoverLen] = uint(HCIDStatus.kycPending);             
        allCoverHolded.push(HoldCover(holdedCoverLen, from, scAddress, 
            coverCurr, coverDetails, coverPeriod));
        userHoldedCover[from].push(allCoverHolded.length.sub(1));
    
    }

    ///@dev sets refund eligible bit.
    ///@param _add user address.
    ///@param status indicates if user have pending kyc.
    function setRefundEligible(address _add, bool status) external onlyInternal {
        refundEligible[_add] = status;
    }

    /// @dev to set current status of particular holded coverID (1 for not completed KYC,
    /// 2 for KYC passed, 3 for failed KYC or full refunded,
    /// 4 for KYC completed but cover not processed)
    function setHoldedCoverIDStatus(uint holdedCoverID, uint status) external onlyInternal {
        holdedCoverIDStatus[holdedCoverID] = status;
    }

    /**
     * @dev to set address of kyc authentication 
     * @param _add is the new address
     */
    function setKycAuthAddress(address _add) external onlyInternal {
        kycAuthAddress = _add;
    }

    /// @dev Changes authorised address for generating quote off chain.
    function changeAuthQuoteEngine(address _add) external onlyInternal {
        authQuoteEngine = _add;
    }

    /**
     * @dev Gets Uint Parameters of a code
     * @param code whose details we want
     * @return string value of the code
     * @return associated amount (time or perc or value) to the code
     */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {
        codeVal = code;

        if (code == "STLP") {
            val = stlp;

        } else if (code == "STL") {
            
            val = stl;

        } else if (code == "PM") {

            val = pm;

        } else if (code == "QUOMIND") {

            val = minDays;

        } else if (code == "QUOTOK") {

            val = tokensRetained;

        }
        
    }

    /// @dev Gets Product details.
    /// @return  _minDays minimum cover period.
    /// @return  _PM Profit margin.
    /// @return  _STL short term Load.
    /// @return  _STLP short term load period.
    function getProductDetails()
        external
        view
        returns (
            uint _minDays,
            uint _pm,
            uint _stl,
            uint _stlp
        )
    {

        _minDays = minDays;
        _pm = pm;
        _stl = stl;
        _stlp = stlp;
    }

    /// @dev Gets total number covers created till date.
    function getCoverLength() external view returns(uint len) {
        return (allCovers.length);
    }

    /// @dev Gets Authorised Engine address.
    function getAuthQuoteEngine() external view returns(address _add) {
        _add = authQuoteEngine;
    }

    /// @dev Gets the Total Sum Assured amount of a given currency.
    function getTotalSumAssured(bytes4 _curr) external view returns(uint amount) {
        amount = currencyCSA[_curr];
    }

    /// @dev Gets all the Cover ids generated by a given address.
    /// @param _add User's address.
    /// @return allCover array of covers.
    function getAllCoversOfUser(address _add) external view returns(uint[] memory allCover) {
        return (userCover[_add]);
    }

    /// @dev Gets total number of covers generated by a given address
    function getUserCoverLength(address _add) external view returns(uint len) {
        len = userCover[_add].length;
    }

    /// @dev Gets the status of a given cover.
    function getCoverStatusNo(uint _cid) external view returns(uint8) {
        return coverStatus[_cid];
    }

    /// @dev Gets the Cover Period (in days) of a given cover.
    function getCoverPeriod(uint _cid) external view returns(uint32 cp) {
        cp = allCovers[_cid].coverPeriod;
    }

    /// @dev Gets the Sum Assured Amount of a given cover.
    function getCoverSumAssured(uint _cid) external view returns(uint sa) {
        sa = allCovers[_cid].sumAssured;
    }

    /// @dev Gets the Currency Name in which a given cover is assured.
    function getCurrencyOfCover(uint _cid) external view returns(bytes4 curr) {
        curr = allCovers[_cid].currencyCode;
    }

    /// @dev Gets the validity date (timestamp) of a given cover.
    function getValidityOfCover(uint _cid) external view returns(uint date) {
        date = allCovers[_cid].validUntil;
    }

    /// @dev Gets Smart contract address of cover.
    function getscAddressOfCover(uint _cid) external view returns(uint, address) {
        return (_cid, allCovers[_cid].scAddress);
    }

    /// @dev Gets the owner address of a given cover.
    function getCoverMemberAddress(uint _cid) external view returns(address payable _add) {
        _add = allCovers[_cid].memberAddress;
    }

    /// @dev Gets the premium amount of a given cover in NXM.
    function getCoverPremiumNXM(uint _cid) external view returns(uint _premiumNXM) {
        _premiumNXM = allCovers[_cid].premiumNXM;
    }

    /// @dev Provides the details of a cover Id
    /// @param _cid cover Id
    /// @return memberAddress cover user address.
    /// @return scAddress smart contract Address 
    /// @return currencyCode currency of cover
    /// @return sumAssured sum assured of cover
    /// @return premiumNXM premium in NXM
    function getCoverDetailsByCoverID1(
        uint _cid
    ) 
        external
        view
        returns (
            uint cid,
            address _memberAddress,
            address _scAddress,
            bytes4 _currencyCode,
            uint _sumAssured,  
            uint premiumNXM 
        ) 
    {
        return (
            _cid,
            allCovers[_cid].memberAddress,
            allCovers[_cid].scAddress,
            allCovers[_cid].currencyCode,
            allCovers[_cid].sumAssured,
            allCovers[_cid].premiumNXM
        );
    }

    /// @dev Provides details of a cover Id
    /// @param _cid cover Id
    /// @return status status of cover.
    /// @return sumAssured Sum assurance of cover.
    /// @return coverPeriod Cover Period of cover (in days).
    /// @return validUntil is validity of cover.
    function getCoverDetailsByCoverID2(
        uint _cid
    )
        external
        view
        returns (
            uint cid,
            uint8 status,
            uint sumAssured,
            uint16 coverPeriod,
            uint validUntil
        ) 
    {

        return (
            _cid,
            coverStatus[_cid],
            allCovers[_cid].sumAssured,
            allCovers[_cid].coverPeriod,
            allCovers[_cid].validUntil
        );
    }

    /// @dev Provides details of a holded cover Id
    /// @param _hcid holded cover Id
    /// @return scAddress SmartCover address of cover.
    /// @return coverCurr currency of cover.
    /// @return coverPeriod Cover Period of cover (in days).
    function getHoldedCoverDetailsByID1(
        uint _hcid
    )
        external 
        view
        returns (
            uint hcid,
            address scAddress,
            bytes4 coverCurr,
            uint16 coverPeriod
        )
    {
        return (
            _hcid,
            allCoverHolded[_hcid].scAddress,
            allCoverHolded[_hcid].coverCurr, 
            allCoverHolded[_hcid].coverPeriod
        );
    }

    /// @dev Gets total number holded covers created till date.
    function getUserHoldedCoverLength(address _add) external view returns (uint) {
        return userHoldedCover[_add].length;
    }

    /// @dev Gets holded cover index by index of user holded covers.
    function getUserHoldedCoverByIndex(address _add, uint index) external view returns (uint) {
        return userHoldedCover[_add][index];
    }

    /// @dev Provides the details of a holded cover Id
    /// @param _hcid holded cover Id
    /// @return memberAddress holded cover user address.
    /// @return coverDetails array contains SA, Cover Currency Price,Price in NXM, Expiration time of Qoute.    
    function getHoldedCoverDetailsByID2(
        uint _hcid
    ) 
        external
        view
        returns (
            uint hcid,
            address payable memberAddress, 
            uint[] memory coverDetails
        )
    {
        return (
            _hcid,
            allCoverHolded[_hcid].userAddress,
            allCoverHolded[_hcid].coverDetails
        );
    }

    /// @dev Gets the Total Sum Assured amount of a given currency and smart contract address.
    function getTotalSumAssuredSC(address _add, bytes4 _curr) external view returns(uint amount) {
        amount = currencyCSAOfSCAdd[_add][_curr];
    }

    //solhint-disable-next-line
    function changeDependentContractAddress() public {}

    /// @dev Changes the status of a given cover.
    /// @param _cid cover Id.
    /// @param _stat New status.
    function changeCoverStatusNo(uint _cid, uint8 _stat) public onlyInternal {
        coverStatus[_cid] = _stat;
        emit CoverStatusEvent(_cid, _stat);
    }

    /**
     * @dev Updates Uint Parameters of a code
     * @param code whose details we want to update
     * @param val value to set
     */
    function updateUintParameters(bytes8 code, uint val) public {

        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "STLP") {
            _changeSTLP(val);

        } else if (code == "STL") {
            
            _changeSTL(val);

        } else if (code == "PM") {

            _changePM(val);

        } else if (code == "QUOMIND") {

            _changeMinDays(val);

        } else if (code == "QUOTOK") {

            _setTokensRetained(val);

        } else {

            revert("Invalid param code");
        }
        
    }
    
    /// @dev Changes the existing Profit Margin value
    function _changePM(uint _pm) internal {
        pm = _pm;
    }

    /// @dev Changes the existing Short Term Load Period (STLP) value.
    function _changeSTLP(uint _stlp) internal {
        stlp = _stlp;
    }

    /// @dev Changes the existing Short Term Load (STL) value.
    function _changeSTL(uint _stl) internal {
        stl = _stl;
    }

    /// @dev Changes the existing Minimum cover period (in days)
    function _changeMinDays(uint _days) internal {
        minDays = _days;
    }
    
    /**
     * @dev to set the the amount of tokens retained 
     * @param val is the amount retained
     */
    function _setTokensRetained(uint val) internal {
        tokensRetained = val;
    }
}

// File: nexusmutual-contracts/contracts/TokenData.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */
    
pragma solidity 0.5.7;




contract TokenData is Iupgradable {
    using SafeMath for uint;

    address payable public walletAddress;
    uint public lockTokenTimeAfterCoverExp;
    uint public bookTime;
    uint public lockCADays;
    uint public lockMVDays;
    uint public scValidDays;
    uint public joiningFee;
    uint public stakerCommissionPer;
    uint public stakerMaxCommissionPer;
    uint public tokenExponent;
    uint public priceStep;

    struct StakeCommission {
        uint commissionEarned;
        uint commissionRedeemed;
    }

    struct Stake {
        address stakedContractAddress;
        uint stakedContractIndex;
        uint dateAdd;
        uint stakeAmount;
        uint unlockedAmount;
        uint burnedAmount;
        uint unLockableBeforeLastBurn;
    }

    struct Staker {
        address stakerAddress;
        uint stakerIndex;
    }

    struct CoverNote {
        uint amount;
        bool isDeposited;
    }

    /**
     * @dev mapping of uw address to array of sc address to fetch 
     * all staked contract address of underwriter, pushing
     * data into this array of Stake returns stakerIndex 
     */ 
    mapping(address => Stake[]) public stakerStakedContracts; 

    /** 
     * @dev mapping of sc address to array of UW address to fetch
     * all underwritters of the staked smart contract
     * pushing data into this mapped array returns scIndex 
     */
    mapping(address => Staker[]) public stakedContractStakers;

    /**
     * @dev mapping of staked contract Address to the array of StakeCommission
     * here index of this array is stakedContractIndex
     */ 
    mapping(address => mapping(uint => StakeCommission)) public stakedContractStakeCommission;

    mapping(address => uint) public lastCompletedStakeCommission;

    /** 
     * @dev mapping of the staked contract address to the current 
     * staker index who will receive commission.
     */ 
    mapping(address => uint) public stakedContractCurrentCommissionIndex;

    /** 
     * @dev mapping of the staked contract address to the 
     * current staker index to burn token from.
     */ 
    mapping(address => uint) public stakedContractCurrentBurnIndex;

    /** 
     * @dev mapping to return true if Cover Note deposited against coverId
     */ 
    mapping(uint => CoverNote) public depositedCN;

    mapping(address => uint) internal isBookedTokens;

    event Commission(
        address indexed stakedContractAddress,
        address indexed stakerAddress,
        uint indexed scIndex,
        uint commissionAmount
    );

    constructor(address payable _walletAdd) public {
        walletAddress = _walletAdd;
        bookTime = 12 hours;
        joiningFee = 2000000000000000; // 0.002 Ether
        lockTokenTimeAfterCoverExp = 35 days;
        scValidDays = 250;
        lockCADays = 7 days;
        lockMVDays = 2 days;
        stakerCommissionPer = 20;
        stakerMaxCommissionPer = 50;
        tokenExponent = 4;
        priceStep = 1000;

    }

    /**
     * @dev Change the wallet address which receive Joining Fee
     */
    function changeWalletAddress(address payable _address) external onlyInternal {
        walletAddress = _address;
    }

    /**
     * @dev Gets Uint Parameters of a code
     * @param code whose details we want
     * @return string value of the code
     * @return associated amount (time or perc or value) to the code
     */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {
        codeVal = code;
        if (code == "TOKEXP") {

            val = tokenExponent; 

        } else if (code == "TOKSTEP") {

            val = priceStep;

        } else if (code == "RALOCKT") {

            val = scValidDays;

        } else if (code == "RACOMM") {

            val = stakerCommissionPer;

        } else if (code == "RAMAXC") {

            val = stakerMaxCommissionPer;

        } else if (code == "CABOOKT") {

            val = bookTime / (1 hours);

        } else if (code == "CALOCKT") {

            val = lockCADays / (1 days);

        } else if (code == "MVLOCKT") {

            val = lockMVDays / (1 days);

        } else if (code == "QUOLOCKT") {

            val = lockTokenTimeAfterCoverExp / (1 days);

        } else if (code == "JOINFEE") {

            val = joiningFee;

        } 
    }

    /**
    * @dev Just for interface
    */
    function changeDependentContractAddress() public { //solhint-disable-line
    }
    
    /**
     * @dev to get the contract staked by a staker 
     * @param _stakerAddress is the address of the staker
     * @param _stakerIndex is the index of staker
     * @return the address of staked contract
     */
    function getStakerStakedContractByIndex(
        address _stakerAddress,
        uint _stakerIndex
    ) 
        public
        view
        returns (address stakedContractAddress) 
    {
        stakedContractAddress = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractAddress;
    }

    /**
     * @dev to get the staker's staked burned 
     * @param _stakerAddress is the address of the staker
     * @param _stakerIndex is the index of staker
     * @return amount burned
     */
    function getStakerStakedBurnedByIndex(
        address _stakerAddress,
        uint _stakerIndex
    ) 
        public
        view
        returns (uint burnedAmount) 
    {
        burnedAmount = stakerStakedContracts[
            _stakerAddress][_stakerIndex].burnedAmount;
    }

    /**
     * @dev to get the staker's staked unlockable before the last burn 
     * @param _stakerAddress is the address of the staker
     * @param _stakerIndex is the index of staker
     * @return unlockable staked tokens
     */
    function getStakerStakedUnlockableBeforeLastBurnByIndex(
        address _stakerAddress,
        uint _stakerIndex
    ) 
        public
        view
        returns (uint unlockable) 
    {
        unlockable = stakerStakedContracts[
            _stakerAddress][_stakerIndex].unLockableBeforeLastBurn;
    }

    /**
     * @dev to get the staker's staked contract index 
     * @param _stakerAddress is the address of the staker
     * @param _stakerIndex is the index of staker
     * @return is the index of the smart contract address
     */
    function getStakerStakedContractIndex(
        address _stakerAddress,
        uint _stakerIndex
    ) 
        public
        view
        returns (uint scIndex) 
    {
        scIndex = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractIndex;
    }

    /**
     * @dev to get the staker index of the staked contract
     * @param _stakedContractAddress is the address of the staked contract
     * @param _stakedContractIndex is the index of staked contract
     * @return is the index of the staker
     */
    function getStakedContractStakerIndex(
        address _stakedContractAddress,
        uint _stakedContractIndex
    ) 
        public
        view
        returns (uint sIndex) 
    {
        sIndex = stakedContractStakers[
            _stakedContractAddress][_stakedContractIndex].stakerIndex;
    }

    /**
     * @dev to get the staker's initial staked amount on the contract 
     * @param _stakerAddress is the address of the staker
     * @param _stakerIndex is the index of staker
     * @return staked amount
     */
    function getStakerInitialStakedAmountOnContract(
        address _stakerAddress,
        uint _stakerIndex
    )
        public 
        view
        returns (uint amount)
    {
        amount = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakeAmount;
    }

    /**
     * @dev to get the staker's staked contract length 
     * @param _stakerAddress is the address of the staker
     * @return length of staked contract
     */
    function getStakerStakedContractLength(
        address _stakerAddress
    ) 
        public
        view
        returns (uint length)
    {
        length = stakerStakedContracts[_stakerAddress].length;
    }

    /**
     * @dev to get the staker's unlocked tokens which were staked 
     * @param _stakerAddress is the address of the staker
     * @param _stakerIndex is the index of staker
     * @return amount
     */
    function getStakerUnlockedStakedTokens(
        address _stakerAddress,
        uint _stakerIndex
    )
        public 
        view
        returns (uint amount)
    {
        amount = stakerStakedContracts[
            _stakerAddress][_stakerIndex].unlockedAmount;
    }

    /**
     * @dev pushes the unlocked staked tokens by a staker.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker to distribute commission.
     * @param _amount amount to be given as commission.
     */ 
    function pushUnlockedStakedTokens(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )   
        public
        onlyInternal
    {   
        stakerStakedContracts[_stakerAddress][
            _stakerIndex].unlockedAmount = stakerStakedContracts[_stakerAddress][
                _stakerIndex].unlockedAmount.add(_amount);
    }

    /**
     * @dev pushes the Burned tokens for a staker.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker.
     * @param _amount amount to be burned.
     */ 
    function pushBurnedTokens(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )   
        public
        onlyInternal
    {   
        stakerStakedContracts[_stakerAddress][
            _stakerIndex].burnedAmount = stakerStakedContracts[_stakerAddress][
                _stakerIndex].burnedAmount.add(_amount);
    }

    /**
     * @dev pushes the unLockable tokens for a staker before last burn.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker.
     * @param _amount amount to be added to unlockable.
     */ 
    function pushUnlockableBeforeLastBurnTokens(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )   
        public
        onlyInternal
    {   
        stakerStakedContracts[_stakerAddress][
            _stakerIndex].unLockableBeforeLastBurn = stakerStakedContracts[_stakerAddress][
                _stakerIndex].unLockableBeforeLastBurn.add(_amount);
    }

    /**
     * @dev sets the unLockable tokens for a staker before last burn.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker.
     * @param _amount amount to be added to unlockable.
     */ 
    function setUnlockableBeforeLastBurnTokens(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )   
        public
        onlyInternal
    {   
        stakerStakedContracts[_stakerAddress][
            _stakerIndex].unLockableBeforeLastBurn = _amount;
    }

    /**
     * @dev pushes the earned commission earned by a staker.
     * @param _stakerAddress address of staker.
     * @param _stakedContractAddress address of smart contract.
     * @param _stakedContractIndex index of the staker to distribute commission.
     * @param _commissionAmount amount to be given as commission.
     */ 
    function pushEarnedStakeCommissions(
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex,
        uint _commissionAmount
    )   
        public
        onlyInternal
    {
        stakedContractStakeCommission[_stakedContractAddress][_stakedContractIndex].
            commissionEarned = stakedContractStakeCommission[_stakedContractAddress][
                _stakedContractIndex].commissionEarned.add(_commissionAmount);
                
        emit Commission(
            _stakerAddress,
            _stakedContractAddress,
            _stakedContractIndex,
            _commissionAmount
        );
    }

    /**
     * @dev pushes the redeemed commission redeemed by a staker.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker to distribute commission.
     * @param _amount amount to be given as commission.
     */ 
    function pushRedeemedStakeCommissions(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )   
        public
        onlyInternal
    {   
        uint stakedContractIndex = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractIndex;
        address stakedContractAddress = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractAddress;
        stakedContractStakeCommission[stakedContractAddress][stakedContractIndex].
            commissionRedeemed = stakedContractStakeCommission[
                stakedContractAddress][stakedContractIndex].commissionRedeemed.add(_amount);
    }

    /**
     * @dev Gets stake commission given to an underwriter
     * for particular stakedcontract on given index.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker commission.
     */ 
    function getStakerEarnedStakeCommission(
        address _stakerAddress,
        uint _stakerIndex
    )
        public 
        view
        returns (uint) 
    {
        return _getStakerEarnedStakeCommission(_stakerAddress, _stakerIndex);
    }

    /**
     * @dev Gets stake commission redeemed by an underwriter
     * for particular staked contract on given index.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker commission.
     * @return commissionEarned total amount given to staker.
     */ 
    function getStakerRedeemedStakeCommission(
        address _stakerAddress,
        uint _stakerIndex
    )
        public 
        view
        returns (uint) 
    {
        return _getStakerRedeemedStakeCommission(_stakerAddress, _stakerIndex);
    }

    /**
     * @dev Gets total stake commission given to an underwriter
     * @param _stakerAddress address of staker.
     * @return totalCommissionEarned total commission earned by staker.
     */ 
    function getStakerTotalEarnedStakeCommission(
        address _stakerAddress
    )
        public 
        view
        returns (uint totalCommissionEarned) 
    {
        totalCommissionEarned = 0;
        for (uint i = 0; i < stakerStakedContracts[_stakerAddress].length; i++) {
            totalCommissionEarned = totalCommissionEarned.
                add(_getStakerEarnedStakeCommission(_stakerAddress, i));
        }
    }

    /**
     * @dev Gets total stake commission given to an underwriter
     * @param _stakerAddress address of staker.
     * @return totalCommissionEarned total commission earned by staker.
     */ 
    function getStakerTotalReedmedStakeCommission(
        address _stakerAddress
    )
        public 
        view
        returns(uint totalCommissionRedeemed) 
    {
        totalCommissionRedeemed = 0;
        for (uint i = 0; i < stakerStakedContracts[_stakerAddress].length; i++) {
            totalCommissionRedeemed = totalCommissionRedeemed.add(
                _getStakerRedeemedStakeCommission(_stakerAddress, i));
        }
    }

    /**
     * @dev set flag to deposit/ undeposit cover note 
     * against a cover Id
     * @param coverId coverId of Cover
     * @param flag true/false for deposit/undeposit
     */
    function setDepositCN(uint coverId, bool flag) public onlyInternal {

        if (flag == true) {
            require(!depositedCN[coverId].isDeposited, "Cover note already deposited");    
        }

        depositedCN[coverId].isDeposited = flag;
    }

    /**
     * @dev set locked cover note amount
     * against a cover Id
     * @param coverId coverId of Cover
     * @param amount amount of nxm to be locked
     */
    function setDepositCNAmount(uint coverId, uint amount) public onlyInternal {

        depositedCN[coverId].amount = amount;
    }

    /**
     * @dev to get the staker address on a staked contract 
     * @param _stakedContractAddress is the address of the staked contract in concern
     * @param _stakedContractIndex is the index of staked contract's index
     * @return address of staker
     */
    function getStakedContractStakerByIndex(
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        public
        view
        returns (address stakerAddress)
    {
        stakerAddress = stakedContractStakers[
            _stakedContractAddress][_stakedContractIndex].stakerAddress;
    }

    /**
     * @dev to get the length of stakers on a staked contract 
     * @param _stakedContractAddress is the address of the staked contract in concern
     * @return length in concern
     */
    function getStakedContractStakersLength(
        address _stakedContractAddress
    ) 
        public
        view
        returns (uint length)
    {
        length = stakedContractStakers[_stakedContractAddress].length;
    } 
    
    /**
     * @dev Adds a new stake record.
     * @param _stakerAddress staker address.
     * @param _stakedContractAddress smart contract address.
     * @param _amount amountof NXM to be staked.
     */
    function addStake(
        address _stakerAddress,
        address _stakedContractAddress,
        uint _amount
    ) 
        public
        onlyInternal
        returns(uint scIndex) 
    {
        scIndex = (stakedContractStakers[_stakedContractAddress].push(
            Staker(_stakerAddress, stakerStakedContracts[_stakerAddress].length))).sub(1);
        stakerStakedContracts[_stakerAddress].push(
            Stake(_stakedContractAddress, scIndex, now, _amount, 0, 0, 0));
    }

    /**
     * @dev books the user's tokens for maintaining Assessor Velocity, 
     * i.e. once a token is used to cast a vote as a Claims assessor,
     * @param _of user's address.
     */
    function bookCATokens(address _of) public onlyInternal {
        require(!isCATokensBooked(_of), "Tokens already booked");
        isBookedTokens[_of] = now.add(bookTime);
    }

    /**
     * @dev to know if claim assessor's tokens are booked or not 
     * @param _of is the claim assessor's address in concern
     * @return boolean representing the status of tokens booked
     */
    function isCATokensBooked(address _of) public view returns(bool res) {
        if (now < isBookedTokens[_of])
            res = true;
    }

    /**
     * @dev Sets the index which will receive commission.
     * @param _stakedContractAddress smart contract address.
     * @param _index current index.
     */
    function setStakedContractCurrentCommissionIndex(
        address _stakedContractAddress,
        uint _index
    )
        public
        onlyInternal
    {
        stakedContractCurrentCommissionIndex[_stakedContractAddress] = _index;
    }

    /**
     * @dev Sets the last complete commission index
     * @param _stakerAddress smart contract address.
     * @param _index current index.
     */
    function setLastCompletedStakeCommissionIndex(
        address _stakerAddress,
        uint _index
    )
        public
        onlyInternal
    {
        lastCompletedStakeCommission[_stakerAddress] = _index;
    }

    /**
     * @dev Sets the index till which commission is distrubuted.
     * @param _stakedContractAddress smart contract address.
     * @param _index current index.
     */
    function setStakedContractCurrentBurnIndex(
        address _stakedContractAddress,
        uint _index
    )
        public
        onlyInternal
    {
        stakedContractCurrentBurnIndex[_stakedContractAddress] = _index;
    }

    /**
     * @dev Updates Uint Parameters of a code
     * @param code whose details we want to update
     * @param val value to set
     */
    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "TOKEXP") {

            _setTokenExponent(val); 

        } else if (code == "TOKSTEP") {

            _setPriceStep(val);

        } else if (code == "RALOCKT") {

            _changeSCValidDays(val);

        } else if (code == "RACOMM") {

            _setStakerCommissionPer(val);

        } else if (code == "RAMAXC") {

            _setStakerMaxCommissionPer(val);

        } else if (code == "CABOOKT") {

            _changeBookTime(val * 1 hours);

        } else if (code == "CALOCKT") {

            _changelockCADays(val * 1 days);

        } else if (code == "MVLOCKT") {

            _changelockMVDays(val * 1 days);

        } else if (code == "QUOLOCKT") {

            _setLockTokenTimeAfterCoverExp(val * 1 days);

        } else if (code == "JOINFEE") {

            _setJoiningFee(val);

        } else {
            revert("Invalid param code");
        } 
    }

    /**
     * @dev Internal function to get stake commission given to an 
     * underwriter for particular stakedcontract on given index.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker commission.
     */ 
    function _getStakerEarnedStakeCommission(
        address _stakerAddress,
        uint _stakerIndex
    )
        internal
        view 
        returns (uint amount) 
    {
        uint _stakedContractIndex;
        address _stakedContractAddress;
        _stakedContractAddress = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractAddress;
        _stakedContractIndex = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractIndex;
        amount = stakedContractStakeCommission[
            _stakedContractAddress][_stakedContractIndex].commissionEarned;
    }

    /**
     * @dev Internal function to get stake commission redeemed by an 
     * underwriter for particular stakedcontract on given index.
     * @param _stakerAddress address of staker.
     * @param _stakerIndex index of the staker commission.
     */ 
    function _getStakerRedeemedStakeCommission(
        address _stakerAddress,
        uint _stakerIndex
    )
        internal
        view 
        returns (uint amount) 
    {
        uint _stakedContractIndex;
        address _stakedContractAddress;
        _stakedContractAddress = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractAddress;
        _stakedContractIndex = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractIndex;
        amount = stakedContractStakeCommission[
            _stakedContractAddress][_stakedContractIndex].commissionRedeemed;
    }

    /**
     * @dev to set the percentage of staker commission 
     * @param _val is new percentage value
     */
    function _setStakerCommissionPer(uint _val) internal {
        stakerCommissionPer = _val;
    }

    /**
     * @dev to set the max percentage of staker commission 
     * @param _val is new percentage value
     */
    function _setStakerMaxCommissionPer(uint _val) internal {
        stakerMaxCommissionPer = _val;
    }

    /**
     * @dev to set the token exponent value 
     * @param _val is new value
     */
    function _setTokenExponent(uint _val) internal {
        tokenExponent = _val;
    }

    /**
     * @dev to set the price step 
     * @param _val is new value
     */
    function _setPriceStep(uint _val) internal {
        priceStep = _val;
    }

    /**
     * @dev Changes number of days for which NXM needs to staked in case of underwriting
     */ 
    function _changeSCValidDays(uint _days) internal {
        scValidDays = _days;
    }

    /**
     * @dev Changes the time period up to which tokens will be locked.
     *      Used to generate the validity period of tokens booked by
     *      a user for participating in claim's assessment/claim's voting.
     */ 
    function _changeBookTime(uint _time) internal {
        bookTime = _time;
    }

    /**
     * @dev Changes lock CA days - number of days for which tokens 
     * are locked while submitting a vote.
     */ 
    function _changelockCADays(uint _val) internal {
        lockCADays = _val;
    }
    
    /**
     * @dev Changes lock MV days - number of days for which tokens are locked
     * while submitting a vote.
     */ 
    function _changelockMVDays(uint _val) internal {
        lockMVDays = _val;
    }

    /**
     * @dev Changes extra lock period for a cover, post its expiry.
     */ 
    function _setLockTokenTimeAfterCoverExp(uint time) internal {
        lockTokenTimeAfterCoverExp = time;
    }

    /**
     * @dev Set the joining fee for membership
     */
    function _setJoiningFee(uint _amount) internal {
        joiningFee = _amount;
    }
}

// File: nexusmutual-contracts/contracts/external/oraclize/ethereum-api/usingOraclize.sol

/*

ORACLIZE_API

Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/
pragma solidity >= 0.5.0 < 0.6.0; // Incompatible compiler version - please select a compiler within the stated pragma range, or use a different version of the oraclizeAPI!

// Dummy contract only used to emit to end-user they are using wrong solc
contract solcChecker {
/* INCOMPATIBLE SOLC: import the following instead: "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol" */ function f(bytes calldata x) external;
}

contract OraclizeI {

    address public cbAddress;

    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function getPrice(string memory _datasource) public returns (uint _dsprice);
    function randomDS_getSessionPubKeyHash() external view returns (bytes32 _sessionKeyHash);
    function getPrice(string memory _datasource, uint _gasLimit) public returns (uint _dsprice);
    function queryN(uint _timestamp, string memory _datasource, bytes memory _argN) public payable returns (bytes32 _id);
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns (bytes32 _id);
}

contract OraclizeAddrResolverI {
    function getAddress() public returns (address _address);
}
/*

Begin solidity-cborutils

https://github.com/smartcontractkit/solidity-cborutils

MIT License

Copyright (c) 2018 SmartContract ChainLink, Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/
library Buffer {

    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity; // Allocate space for the buffer data
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }
    /**
      * @dev Appends a byte array to the end of the buffer. Resizes if doing so
      *      would exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            dest := add(add(bufptr, buflen), 32) // Start address = buffer address + buffer length + sizeof(buffer length)
            mstore(bufptr, add(buflen, mload(_data))) // Update buffer length
            src := add(_data, 32)
        }
        for(; len >= 32; len -= 32) { // Copy word-length chunks while possible
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = 256 ** (32 - len) - 1; // Copy remaining bytes
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), 32) // Address = buffer address + buffer length + sizeof(buffer length)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1)) // Update buffer length
        }
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), _len) // Address = buffer address + buffer length + sizeof(buffer length) + len
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len)) // Update buffer length
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}
/*

End solidity-cborutils

*/
contract usingOraclize {

    using CBOR for Buffer.buffer;

    OraclizeI oraclize;
    OraclizeAddrResolverI OAR;

    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;

    byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

    string oraclize_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) oraclize_randomDS_args;
    mapping(bytes32 => bool) oraclize_randomDS_sessionKeysHashVerified;

    modifier oraclizeAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            oraclize_setNetwork(networkID_auto);
        }
        if (address(oraclize) != OAR.getAddress()) {
            oraclize = OraclizeI(OAR.getAddress());
        }
        _;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string memory _result, bytes memory _proof) {
        // RandomDS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (uint8(_proof[2]) == uint8(1)));
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);
        _;
    }

    function oraclize_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      return oraclize_setNetwork();
      _networkID; // silence the warning and remain backwards compatible
    }

    function oraclize_setNetworkName(string memory _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string memory _networkName) {
        return oraclize_network_name;
    }

    function oraclize_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) { //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) { //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) { //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) { //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) { //goerli testnet
            OAR = OraclizeAddrResolverI(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41);
            oraclize_setNetworkName("eth_goerli");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) { //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) { //ether.camp ide
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) { //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 _myid, string memory _result) public {
        __callback(_myid, _result, new bytes(0));
    }

    function __callback(bytes32 _myid, string memory _result, bytes memory _proof) public {
      return;
      _myid; _result; _proof; // Silence compiler warnings
    }

    function oraclize_getPrice(string memory _datasource) oraclizeAPI internal returns (uint _queryPrice) {
        return oraclize.getPrice(_datasource);
    }

    function oraclize_getPrice(string memory _datasource, uint _gasLimit) oraclizeAPI internal returns (uint _queryPrice) {
        return oraclize.getPrice(_datasource, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query.value(price)(0, _datasource, _arg);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query.value(price)(_timestamp, _datasource, _arg);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource,_gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query_withGasLimit.value(price)(_timestamp, _datasource, _arg, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
           return 0; // Unexpectedly high price
        }
        return oraclize.query_withGasLimit.value(price)(0, _datasource, _arg, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg1, string memory _arg2) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query2.value(price)(0, _datasource, _arg1, _arg2);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query2.value(price)(_timestamp, _datasource, _arg1, _arg2);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query2_withGasLimit.value(price)(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query2_withGasLimit.value(price)(0, _datasource, _arg1, _arg2, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN.value(price)(0, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN.value(price)(_timestamp, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(_timestamp, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(0, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN.value(price)(0, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN.value(price)(_timestamp, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(_timestamp, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(0, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_setProof(byte _proofP) oraclizeAPI internal {
        return oraclize.setProofType(_proofP);
    }


    function oraclize_cbAddress() oraclizeAPI internal returns (address _callbackAddress) {
        return oraclize.cbAddress();
    }

    function getCodeSize(address _addr) view internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function oraclize_setCustomGasPrice(uint _gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(_gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32 _sessionKeyHash) {
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int _returnCode) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2 ** 128 - 1)) {
            return -1;
        } else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int(i);
                    }
                }
            }
            return -1;
        }
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10; // Convert from seconds to ledger timer ticks
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            /*
             The following variables can be relaxed.
             Check the relaxed random contract at https://github.com/oraclize/ethereum-examples
             for an idea on how to override and replace commit hash variables.
            */
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);
        bytes memory delay_bytes8_left = new bytes(8);
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))
        }
        oraclize_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 _queryId, bytes32 _commitment) internal {
        oraclize_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(bytes32 _tosignh, bytes memory _dersig, bytes memory _pubkey) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(_dersig, offset + (uint(uint8(_dersig[offset - 1])) - 0x20), 32, sigs_, 0);
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes memory _proof, uint _sig2offset) internal returns (bool _proofVerified) {
        bool sigok;
        // Random DS Proof Step 6: Verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(uint8(1)); //role
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }
        // Random DS Proof Step 7: Verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string memory _result, bytes memory _proof) internal returns (uint8 _returnCode) {
        // Random DS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        if ((_proof[0] != "L") || (_proof[1] != "P") || (uint8(_proof[2]) != uint8(1))) {
            return 1;
        }
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(bytes32 _content, bytes memory _prefix, uint _nRandomBytes) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i< _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes memory _proof, bytes32 _queryId, bytes memory _result, string memory _contextName) internal returns (bool _proofVerified) {
        // Random DS Proof Step 2: The unique keyhash has to match with the sha256 of (context name + _queryId)
        uint ledgerProofLength = 3 + 65 + (uint(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_contextName, _queryId)))))) {
            return false;
        }
        bytes memory sig1 = new bytes(uint(uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])) + 2);
        copyBytes(_proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);
        // Random DS Proof Step 3: We assume sig1 is valid (it will be verified during step 5) and we verify if '_result' is the _prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), _result, uint(uint8(_proof[ledgerProofLength + 32 + 8])))) {
            return false;
        }
        // Random DS Proof Step 4: Commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[_queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))) { //unonce, nbytes and sessionKeyHash match
            delete oraclize_randomDS_args[_queryId];
        } else return false;
        // Random DS Proof Step 5: Validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }
        // Verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (!oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(_proof, sig2offset);
        }
        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function copyBytes(bytes memory _from, uint _fromOffset, uint _length, bytes memory _to, uint _toOffset) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength); // Buffer too small. Should be a better way?
        uint i = 32 + _fromOffset; // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
     Duplicate Solidity's ecrecover, but catching the CALL return value
    */
    function safer_ecrecover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal returns (bool _success, address _recoveredAddress) {
        /*
         We do our own memory management here. Solidity uses memory offset
         0x40 to store the current end of memory. We write past it (as
         writes are memory extensions), but don't update the offset so
         Solidity will reuse it. The memory used here is only needed for
         this context.
         FIXME: inline assembly can't access return values
        */
        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32) // NOTE: we can reuse the request memory because we deal with the return code.
            addr := mload(size)
        }
        return (ret, addr);
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function ecrecovery(bytes32 _hash, bytes memory _sig) internal returns (bool _success, address _recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }
        /*
         The signature format is a compact form of:
           {bytes32 r}{bytes32 s}{uint8 v}
         Compact means, uint8 is not padded to 32 bytes.
        */
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            /*
             Here we are loading the last 32 bytes. We exploit the fact that
             'mload' will pad with zeroes if we overread.
             There is no 'mload8' to do this, but that would be nicer.
            */
            v := byte(0, mload(add(_sig, 96)))
            /*
              Alternative solution:
              'byte' is not working due to the Solidity parser, so lets
              use the second best option, 'and'
              v := and(mload(add(_sig, 65)), 255)
            */
        }
        /*
         albeit non-transactional signatures are not specified by the YP, one would expect it
         to match the YP range of [27, 28]
         geth uses [0, 1] and some clients have followed. This might change, see:
         https://github.com/ethereum/go-ethereum/issues/2053
        */
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }
}
/*

END ORACLIZE_API

*/

// File: nexusmutual-contracts/contracts/Quotation.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;










contract Quotation is Iupgradable {
    using SafeMath for uint;

    TokenFunctions internal tf;
    TokenController internal tc;
    TokenData internal td;
    Pool1 internal p1;
    PoolData internal pd;
    QuotationData internal qd;
    MCR internal m1;
    MemberRoles internal mr;
    bool internal locked;

    event RefundEvent(address indexed user, bool indexed status, uint holdedCoverID, bytes32 reason);

    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }
    
    /**
     * @dev Iupgradable Interface to update dependent contract address
     */
    function changeDependentContractAddress() public onlyInternal {
        m1 = MCR(ms.getLatestAddress("MC"));
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tc = TokenController(ms.getLatestAddress("TC"));
        td = TokenData(ms.getLatestAddress("TD"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        p1 = Pool1(ms.getLatestAddress("P1"));
        pd = PoolData(ms.getLatestAddress("PD"));
        mr = MemberRoles(ms.getLatestAddress("MR"));
    }

    function sendEther() public payable {
        
    }

    /**
     * @dev Expires a cover after a set period of time.
     * Changes the status of the Cover and reduces the current
     * sum assured of all areas in which the quotation lies
     * Unlocks the CN tokens of the cover. Updates the Total Sum Assured value.
     * @param _cid Cover Id.
     */ 
    function expireCover(uint _cid) public {
        require(checkCoverExpired(_cid) && qd.getCoverStatusNo(_cid) != uint(QuotationData.CoverStatus.CoverExpired));
        
        tf.unlockCN(_cid);
        bytes4 curr;
        address scAddress;
        uint sumAssured;
        (, , scAddress, curr, sumAssured, ) = qd.getCoverDetailsByCoverID1(_cid);
        if (qd.getCoverStatusNo(_cid) != uint(QuotationData.CoverStatus.ClaimAccepted))
            _removeSAFromCSA(_cid, sumAssured);
        qd.changeCoverStatusNo(_cid, uint8(QuotationData.CoverStatus.CoverExpired));       
    }

    /**
     * @dev Checks if a cover should get expired/closed or not.
     * @param _cid Cover Index.
     * @return expire true if the Cover's time has expired, false otherwise.
     */ 
    function checkCoverExpired(uint _cid) public view returns(bool expire) {

        expire = qd.getValidityOfCover(_cid) < uint64(now);

    }

    /**
     * @dev Updates the Sum Assured Amount of all the quotation.
     * @param _cid Cover id
     * @param _amount that will get subtracted Current Sum Assured 
     * amount that comes under a quotation.
     */ 
    function removeSAFromCSA(uint _cid, uint _amount) public onlyInternal {
        _removeSAFromCSA(_cid, _amount);        
    }

    /**
     * @dev Makes Cover funded via NXM tokens.
     * @param smartCAdd Smart Contract Address
     */ 
    function makeCoverUsingNXMTokens(
        uint[] memory coverDetails,
        uint16 coverPeriod,
        bytes4 coverCurr,
        address smartCAdd,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        isMemberAndcheckPause
    {
        
        tc.burnFrom(msg.sender, coverDetails[2]); //need burn allowance
        _verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }

    /**
     * @dev Verifies cover details signed off chain.
     * @param from address of funder.
     * @param scAddress Smart Contract Address
     */
    function verifyCoverDetails(
        address payable from,
        address scAddress,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        onlyInternal
    {
        _verifyCoverDetails(
            from,
            scAddress,
            coverCurr,
            coverDetails,
            coverPeriod,
            _v,
            _r,
            _s
        );
    }

    /** 
     * @dev Verifies signature.
     * @param coverDetails details related to cover.
     * @param coverPeriod validity of cover.
     * @param smaratCA smarat contract address.
     * @param _v argument from vrs hash.
     * @param _r argument from vrs hash.
     * @param _s argument from vrs hash.
     */ 
    function verifySign(
        uint[] memory coverDetails,
        uint16 coverPeriod,
        bytes4 curr,
        address smaratCA,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) 
        public
        view
        returns(bool)
    {
        require(smaratCA != address(0));
        require(pd.capReached() == 1, "Can not buy cover until cap reached for 1st time");
        bytes32 hash = getOrderHash(coverDetails, coverPeriod, curr, smaratCA);
        return isValidSignature(hash, _v, _r, _s);
    }

    /**
     * @dev Gets order hash for given cover details.
     * @param coverDetails details realted to cover.
     * @param coverPeriod validity of cover.
     * @param smaratCA smarat contract address.
     */ 
    function getOrderHash(
        uint[] memory coverDetails,
        uint16 coverPeriod,
        bytes4 curr,
        address smaratCA
    ) 
        public
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                coverDetails[0],
                curr, coverPeriod,
                smaratCA,
                coverDetails[1],
                coverDetails[2],
                coverDetails[3],
                coverDetails[4],
                address(this)
            )
        );
    }

    /**
     * @dev Verifies signature.
     * @param hash order hash
     * @param v argument from vrs hash.
     * @param r argument from vrs hash.
     * @param s argument from vrs hash.
     */  
    function isValidSignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        address a = ecrecover(prefixedHash, v, r, s);
        return (a == qd.getAuthQuoteEngine());
    }

    /**
     * @dev to get the status of recently holded coverID 
     * @param userAdd is the user address in concern
     * @return the status of the concerned coverId
     */
    function getRecentHoldedCoverIdStatus(address userAdd) public view returns(int) {

        uint holdedCoverLen = qd.getUserHoldedCoverLength(userAdd);
        if (holdedCoverLen == 0) {
            return -1;
        } else {
            uint holdedCoverID = qd.getUserHoldedCoverByIndex(userAdd, holdedCoverLen.sub(1));
            return int(qd.holdedCoverIDStatus(holdedCoverID));
        }
    }
    
    /**
     * @dev to initiate the membership and the cover 
     * @param smartCAdd is the smart contract address to make cover on
     * @param coverCurr is the currency used to make cover
     * @param coverDetails list of details related to cover like cover amount, expire time, coverCurrPrice and priceNXM
     * @param coverPeriod is cover period for which cover is being bought
     * @param _v argument from vrs hash 
     * @param _r argument from vrs hash 
     * @param _s argument from vrs hash 
     */
    function initiateMembershipAndCover(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) 
        public
        payable
        checkPause
    {
        require(coverDetails[3] > now);
        require(!qd.timestampRepeated(coverDetails[4]));
        qd.setTimestampRepeated(coverDetails[4]);
        require(!ms.isMember(msg.sender));
        require(qd.refundEligible(msg.sender) == false);
        uint joinFee = td.joiningFee();
        uint totalFee = joinFee;
        if (coverCurr == "ETH") {
            totalFee = joinFee.add(coverDetails[1]);
        } else {
            IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));
            require(erc20.transferFrom(msg.sender, address(this), coverDetails[1]));
        }
        require(msg.value == totalFee);
        require(verifySign(coverDetails, coverPeriod, coverCurr, smartCAdd, _v, _r, _s));
        qd.addHoldCover(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod);
        qd.setRefundEligible(msg.sender, true);
    }

    /**
     * @dev to get the verdict of kyc process 
     * @param status is the kyc status
     * @param _add is the address of member
     */
    function kycVerdict(address _add, bool status) public checkPause noReentrancy {
        require(msg.sender == qd.kycAuthAddress());
        _kycTrigger(status, _add);
    }

    /**
     * @dev transfering Ethers to newly created quotation contract.
     */  
    function transferAssetsToNewContract(address newAdd) public onlyInternal noReentrancy {
        uint amount = address(this).balance;
        IERC20 erc20;
        if (amount > 0) {
            // newAdd.transfer(amount);   
            Quotation newQT = Quotation(newAdd);
            newQT.sendEther.value(amount)();
        }
        uint currAssetLen = pd.getAllCurrenciesLen();
        for (uint64 i = 1; i < currAssetLen; i++) {
            bytes4 currName = pd.getCurrenciesByIndex(i);
            address currAddr = pd.getCurrencyAssetAddress(currName);
            erc20 = IERC20(currAddr); //solhint-disable-line
            if (erc20.balanceOf(address(this)) > 0) {
                require(erc20.transfer(newAdd, erc20.balanceOf(address(this))));
            }
        }
    }


    /**
     * @dev Creates cover of the quotation, changes the status of the quotation ,
     * updates the total sum assured and locks the tokens of the cover against a quote.
     * @param from Quote member Ethereum address.
     */  

    function _makeCover ( //solhint-disable-line
        address payable from,
        address scAddress,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod
    )
        internal
    {
        uint cid = qd.getCoverLength();
        qd.addCover(coverPeriod, coverDetails[0],
            from, coverCurr, scAddress, coverDetails[1], coverDetails[2]);
        // if cover period of quote is less than 60 days.
        if (coverPeriod <= 60) {
            p1.closeCoverOraclise(cid, uint64(uint(coverPeriod).mul(1 days)));
        }
        uint coverNoteAmount = (coverDetails[2].mul(qd.tokensRetained())).div(100);
        tc.mint(from, coverNoteAmount);
        tf.lockCN(coverNoteAmount, coverPeriod, cid, from);
        qd.addInTotalSumAssured(coverCurr, coverDetails[0]);
        qd.addInTotalSumAssuredSC(scAddress, coverCurr, coverDetails[0]);


        tf.pushStakerRewards(scAddress, coverDetails[2]);
    }

    /**
     * @dev Makes a vover.
     * @param from address of funder.
     * @param scAddress Smart Contract Address
     */  
    function _verifyCoverDetails(
        address payable from,
        address scAddress,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
    {
        require(coverDetails[3] > now);
        require(!qd.timestampRepeated(coverDetails[4]));
        qd.setTimestampRepeated(coverDetails[4]);
        require(verifySign(coverDetails, coverPeriod, coverCurr, scAddress, _v, _r, _s));
        _makeCover(from, scAddress, coverCurr, coverDetails, coverPeriod);

    }

    /**
     * @dev Updates the Sum Assured Amount of all the quotation.
     * @param _cid Cover id
     * @param _amount that will get subtracted Current Sum Assured 
     * amount that comes under a quotation.
     */ 
    function _removeSAFromCSA(uint _cid, uint _amount) internal checkPause {
        address _add;
        bytes4 coverCurr;
        (, , _add, coverCurr, , ) = qd.getCoverDetailsByCoverID1(_cid);
        qd.subFromTotalSumAssured(coverCurr, _amount);        
        qd.subFromTotalSumAssuredSC(_add, coverCurr, _amount);
    }

    /**
     * @dev to trigger the kyc process 
     * @param status is the kyc status
     * @param _add is the address of member
     */
    function _kycTrigger(bool status, address _add) internal {

        uint holdedCoverLen = qd.getUserHoldedCoverLength(_add).sub(1);
        uint holdedCoverID = qd.getUserHoldedCoverByIndex(_add, holdedCoverLen);
        address payable userAdd;
        address scAddress;
        bytes4 coverCurr;
        uint16 coverPeriod;
        uint[]  memory coverDetails = new uint[](4);
        IERC20 erc20;

        (, userAdd, coverDetails) = qd.getHoldedCoverDetailsByID2(holdedCoverID);
        (, scAddress, coverCurr, coverPeriod) = qd.getHoldedCoverDetailsByID1(holdedCoverID);
        require(qd.refundEligible(userAdd));
        qd.setRefundEligible(userAdd, false);
        require(qd.holdedCoverIDStatus(holdedCoverID) == uint(QuotationData.HCIDStatus.kycPending));
        uint joinFee = td.joiningFee();
        if (status) {
            mr.payJoiningFee.value(joinFee)(userAdd);
            if (coverDetails[3] > now) { 
                qd.setHoldedCoverIDStatus(holdedCoverID, uint(QuotationData.HCIDStatus.kycPass));
                address poolAdd = ms.getLatestAddress("P1");
                if (coverCurr == "ETH") {
                    p1.sendEther.value(coverDetails[1])();
                } else {
                    erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr)); //solhint-disable-line
                    require(erc20.transfer(poolAdd, coverDetails[1]));
                }
                emit RefundEvent(userAdd, status, holdedCoverID, "KYC Passed");               
                _makeCover(userAdd, scAddress, coverCurr, coverDetails, coverPeriod);

            } else {
                qd.setHoldedCoverIDStatus(holdedCoverID, uint(QuotationData.HCIDStatus.kycPassNoCover));
                if (coverCurr == "ETH") {
                    userAdd.transfer(coverDetails[1]);
                } else {
                    erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr)); //solhint-disable-line
                    require(erc20.transfer(userAdd, coverDetails[1]));
                }
                emit RefundEvent(userAdd, status, holdedCoverID, "Cover Failed");
            }
        } else {
            qd.setHoldedCoverIDStatus(holdedCoverID, uint(QuotationData.HCIDStatus.kycFailedOrRefunded));
            uint totalRefund = joinFee;
            if (coverCurr == "ETH") {
                totalRefund = coverDetails[1].add(joinFee);
            } else {
                erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr)); //solhint-disable-line
                require(erc20.transfer(userAdd, coverDetails[1]));
            }
            userAdd.transfer(totalRefund);
            emit RefundEvent(userAdd, status, holdedCoverID, "KYC Failed");
        }
              
    }
}

// File: nexusmutual-contracts/contracts/external/uniswap/solidity-interface.sol

pragma solidity 0.5.7;


contract Factory {
    function getExchange(address token) public view returns (address);
    function getToken(address exchange) public view returns (address);
}


contract Exchange { 
    function getEthToTokenInputPrice(uint256 ethSold) public view returns(uint256);

    function getTokenToEthInputPrice(uint256 tokensSold) public view returns(uint256);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline) public payable returns (uint256);

    function ethToTokenTransferInput(uint256 minTokens, uint256 deadline, address recipient)
        public payable returns (uint256);

    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        public payable returns (uint256);

    function tokenToEthTransferInput(uint256 tokensSold, uint256 minEth, uint256 deadline, address recipient) 
        public payable returns (uint256);

    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address tokenAddress
    ) 
        public returns (uint256);

    function tokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        address tokenAddress
    )
        public returns (uint256);
}

// File: nexusmutual-contracts/contracts/Pool2.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;






contract Pool2 is Iupgradable {
    using SafeMath for uint;

    MCR internal m1;
    Pool1 internal p1;
    PoolData internal pd;
    Factory internal factory;
    address public uniswapFactoryAddress;
    uint internal constant DECIMAL1E18 = uint(10) ** 18;
    bool internal locked;

    constructor(address _uniswapFactoryAdd) public {
       
        uniswapFactoryAddress = _uniswapFactoryAdd;
        factory = Factory(_uniswapFactoryAdd);
    }

    function() external payable {}

    event Liquidity(bytes16 typeOf, bytes16 functionName);

    event Rebalancing(bytes4 iaCurr, uint tokenAmount);

    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev to change the uniswap factory address 
     * @param newFactoryAddress is the new factory address in concern
     * @return the status of the concerned coverId
     */
    function changeUniswapFactoryAddress(address newFactoryAddress) external onlyInternal {
        // require(ms.isOwner(msg.sender) || ms.checkIsAuthToGoverned(msg.sender));
        uniswapFactoryAddress = newFactoryAddress;
        factory = Factory(uniswapFactoryAddress);
    }

    /**
     * @dev On upgrade transfer all investment assets and ether to new Investment Pool
     * @param newPoolAddress New Investment Assest Pool address
     */
    function upgradeInvestmentPool(address payable newPoolAddress) external onlyInternal noReentrancy {
        uint len = pd.getInvestmentCurrencyLen();
        for (uint64 i = 1; i < len; i++) {
            bytes4 iaName = pd.getInvestmentCurrencyByIndex(i);
            _upgradeInvestmentPool(iaName, newPoolAddress);
        }

        if (address(this).balance > 0) {
            Pool2 newP2 = Pool2(newPoolAddress);
            newP2.sendEther.value(address(this).balance)();
        }
    }

    /**
     * @dev Internal Swap of assets between Capital 
     * and Investment Sub pool for excess or insufficient  
     * liquidity conditions of a given currency.
     */ 
    function internalLiquiditySwap(bytes4 curr) external onlyInternal noReentrancy {
        uint caBalance;
        uint baseMin;
        uint varMin;
        (, baseMin, varMin) = pd.getCurrencyAssetVarBase(curr);
        caBalance = _getCurrencyAssetsBalance(curr);

        if (caBalance > uint(baseMin).add(varMin).mul(2)) {
            _internalExcessLiquiditySwap(curr, baseMin, varMin, caBalance);
        } else if (caBalance < uint(baseMin).add(varMin)) {
            _internalInsufficientLiquiditySwap(curr, baseMin, varMin, caBalance);
            
        }
    }

    /**
     * @dev Saves a given investment asset details. To be called daily.
     * @param curr array of Investment asset name.
     * @param rate array of investment asset exchange rate.
     * @param date current date in yyyymmdd.
     */ 
    function saveIADetails(bytes4[] calldata curr, uint64[] calldata rate, uint64 date, bool bit) 
    external checkPause noReentrancy {
        bytes4 maxCurr;
        bytes4 minCurr;
        uint64 maxRate;
        uint64 minRate;
        //ONLY NOTARZIE ADDRESS CAN POST
        require(pd.isnotarise(msg.sender));
        (maxCurr, maxRate, minCurr, minRate) = _calculateIARank(curr, rate);
        pd.saveIARankDetails(maxCurr, maxRate, minCurr, minRate, date);
        pd.updatelastDate(date);
        uint len = curr.length;
        for (uint i = 0; i < len; i++) {
            pd.updateIAAvgRate(curr[i], rate[i]);
        }
        if (bit)   //for testing purpose
            _rebalancingLiquidityTrading(maxCurr, maxRate);
        p1.saveIADetailsOracalise(pd.iaRatesTime());
    }

    /**
     * @dev External Trade for excess or insufficient  
     * liquidity conditions of a given currency.
     */ 
    function externalLiquidityTrade() external onlyInternal {
        
        bool triggerTrade;
        bytes4 curr;
        bytes4 minIACurr;
        bytes4 maxIACurr;
        uint amount;
        uint minIARate;
        uint maxIARate;
        uint baseMin;
        uint varMin;
        uint caBalance;


        (maxIACurr, maxIARate, minIACurr, minIARate) = pd.getIARankDetailsByDate(pd.getLastDate());
        uint len = pd.getAllCurrenciesLen();
        for (uint64 i = 0; i < len; i++) {
            curr = pd.getCurrenciesByIndex(i);
            (, baseMin, varMin) = pd.getCurrencyAssetVarBase(curr);
            caBalance = _getCurrencyAssetsBalance(curr);

            if (caBalance > uint(baseMin).add(varMin).mul(2)) { //excess
                amount = caBalance.sub(((uint(baseMin).add(varMin)).mul(3)).div(2)); //*10**18;
                triggerTrade = _externalExcessLiquiditySwap(curr, minIACurr, amount);
            } else if (caBalance < uint(baseMin).add(varMin)) { // insufficient
                amount = (((uint(baseMin).add(varMin)).mul(3)).div(2)).sub(caBalance);
                triggerTrade = _externalInsufficientLiquiditySwap(curr, maxIACurr, amount);
            }

            if (triggerTrade) {
                p1.triggerExternalLiquidityTrade();
            }
        }
    }

    /**
     * Iupgradable Interface to update dependent contract address
     */
    function changeDependentContractAddress() public onlyInternal {
        m1 = MCR(ms.getLatestAddress("MC"));
        pd = PoolData(ms.getLatestAddress("PD"));
        p1 = Pool1(ms.getLatestAddress("P1"));
    }

    function sendEther() public payable {
        
    }

    /** 
     * @dev Gets currency asset balance for a given currency name.
     */   
    function _getCurrencyAssetsBalance(bytes4 _curr) public view returns(uint caBalance) {
        if (_curr == "ETH") {
            caBalance = address(p1).balance;
        } else {
            IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr));
            caBalance = erc20.balanceOf(address(p1));
        }
    }

    /** 
     * @dev Transfers ERC20 investment asset from this Pool to another Pool.
     */ 
    function _transferInvestmentAsset(
        bytes4 _curr,
        address _transferTo,
        uint _amount
    ) 
        internal
    {
        if (_curr == "ETH") {
            if (_amount > address(this).balance)
                _amount = address(this).balance;
            p1.sendEther.value(_amount)();
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
            if (_amount > erc20.balanceOf(address(this)))
                _amount = erc20.balanceOf(address(this));
            require(erc20.transfer(_transferTo, _amount));
        }
    }

    /**
     * @dev to perform rebalancing 
     * @param iaCurr is the investment asset currency
     * @param iaRate is the investment asset rate
     */
    function _rebalancingLiquidityTrading(
        bytes4 iaCurr,
        uint64 iaRate
    ) 
        internal
        checkPause
    {
        uint amountToSell;
        uint totalRiskBal = pd.getLastVfull();
        uint intermediaryEth;
        uint ethVol = pd.ethVolumeLimit();

        totalRiskBal = (totalRiskBal.mul(100000)).div(DECIMAL1E18);
        Exchange exchange;
        if (totalRiskBal > 0) {
            amountToSell = ((totalRiskBal.mul(2).mul(
                iaRate)).mul(pd.variationPercX100())).div(100 * 100 * 100000);
            amountToSell = (amountToSell.mul(
                10**uint(pd.getInvestmentAssetDecimals(iaCurr)))).div(100); // amount of asset to sell

            if (iaCurr != "ETH" && _checkTradeConditions(iaCurr, iaRate, totalRiskBal)) { 
                exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(iaCurr)));
                intermediaryEth = exchange.getTokenToEthInputPrice(amountToSell);
                if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) { 
                    intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                    amountToSell = (exchange.getEthToTokenInputPrice(intermediaryEth).mul(995)).div(1000);
                }
                IERC20 erc20;
                erc20 = IERC20(pd.getCurrencyAssetAddress(iaCurr));
                erc20.approve(address(exchange), amountToSell);
                exchange.tokenToEthSwapInput(amountToSell, (exchange.getTokenToEthInputPrice(
                    amountToSell).mul(995)).div(1000), pd.uniswapDeadline().add(now));
            } else if (iaCurr == "ETH" && _checkTradeConditions(iaCurr, iaRate, totalRiskBal)) {

                _transferInvestmentAsset(iaCurr, ms.getLatestAddress("P1"), amountToSell);
            }
            emit Rebalancing(iaCurr, amountToSell); 
        }
    }

    /**
     * @dev Checks whether trading is required for a  
     * given investment asset at a given exchange rate.
     */ 
    function _checkTradeConditions(
        bytes4 curr,
        uint64 iaRate,
        uint totalRiskBal
    )
        internal
        view
        returns(bool check)
    {
        if (iaRate > 0) {
            uint iaBalance =  _getInvestmentAssetBalance(curr).div(DECIMAL1E18);
            if (iaBalance > 0 && totalRiskBal > 0) {
                uint iaMax;
                uint iaMin;
                uint checkNumber;
                uint z;
                (iaMin, iaMax) = pd.getInvestmentAssetHoldingPerc(curr);
                z = pd.variationPercX100();
                checkNumber = (iaBalance.mul(100 * 100000)).div(totalRiskBal.mul(iaRate));
                if ((checkNumber > ((totalRiskBal.mul(iaMax.add(z))).mul(100000)).div(100)) ||
                    (checkNumber < ((totalRiskBal.mul(iaMin.sub(z))).mul(100000)).div(100)))
                    check = true; //eligibleIA
            }
        }
    }    

    /** 
     * @dev Gets the investment asset rank.
     */ 
    function _getIARank(
        bytes4 curr,
        uint64 rateX100,
        uint totalRiskPoolBalance
    ) 
        internal
        view
        returns (int rhsh, int rhsl) //internal function
    {

        uint currentIAmaxHolding;
        uint currentIAminHolding;
        uint iaBalance = _getInvestmentAssetBalance(curr);
        (currentIAminHolding, currentIAmaxHolding) = pd.getInvestmentAssetHoldingPerc(curr);
        
        if (rateX100 > 0) {
            uint rhsf;
            rhsf = (iaBalance.mul(1000000)).div(totalRiskPoolBalance.mul(rateX100));
            rhsh = int(rhsf - currentIAmaxHolding);
            rhsl = int(rhsf - currentIAminHolding);
        }
    }

    /** 
     * @dev Calculates the investment asset rank.
     */  
    function _calculateIARank(
        bytes4[] memory curr,
        uint64[] memory rate
    )
        internal
        view
        returns(
            bytes4 maxCurr,
            uint64 maxRate,
            bytes4 minCurr,
            uint64 minRate
        )  
    {
        int max = 0;
        int min = -1;
        int rhsh;
        int rhsl;
        uint totalRiskPoolBalance;
        (totalRiskPoolBalance, ) = m1.calVtpAndMCRtp();
        uint len = curr.length;
        for (uint i = 0; i < len; i++) {
            rhsl = 0;
            rhsh = 0;
            if (pd.getInvestmentAssetStatus(curr[i])) {
                (rhsh, rhsl) = _getIARank(curr[i], rate[i], totalRiskPoolBalance);
                if (rhsh > max || i == 0) {
                    max = rhsh;
                    maxCurr = curr[i];
                    maxRate = rate[i];
                }
                if (rhsl < min || rhsl == 0 || i == 0) {
                    min = rhsl;
                    minCurr = curr[i];
                    minRate = rate[i];
                }
            }
        }
    }

    /**
     * @dev to get balance of an investment asset 
     * @param _curr is the investment asset in concern
     * @return the balance
     */
    function _getInvestmentAssetBalance(bytes4 _curr) internal view returns (uint balance) {
        if (_curr == "ETH") {
            balance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
            balance = erc20.balanceOf(address(this));
        }
    }

    /**
     * @dev Creates Excess liquidity trading order for a given currency and a given balance.
     */  
    function _internalExcessLiquiditySwap(bytes4 _curr, uint _baseMin, uint _varMin, uint _caBalance) internal {
        // require(ms.isInternal(msg.sender) || md.isnotarise(msg.sender));
        bytes4 minIACurr;
        // uint amount;
        
        (, , minIACurr, ) = pd.getIARankDetailsByDate(pd.getLastDate());
        if (_curr == minIACurr) {
            // amount = _caBalance.sub(((_baseMin.add(_varMin)).mul(3)).div(2)); //*10**18;
            p1.transferCurrencyAsset(_curr, _caBalance.sub(((_baseMin.add(_varMin)).mul(3)).div(2)));
        } else {
            p1.triggerExternalLiquidityTrade();
        }
    }

    /** 
     * @dev insufficient liquidity swap  
     * for a given currency and a given balance.
     */ 
    function _internalInsufficientLiquiditySwap(bytes4 _curr, uint _baseMin, uint _varMin, uint _caBalance) internal {
        
        bytes4 maxIACurr;
        uint amount;
        
        (maxIACurr, , , ) = pd.getIARankDetailsByDate(pd.getLastDate());
        
        if (_curr == maxIACurr) {
            amount = (((_baseMin.add(_varMin)).mul(3)).div(2)).sub(_caBalance);
            _transferInvestmentAsset(_curr, ms.getLatestAddress("P1"), amount);
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(maxIACurr));
            if ((maxIACurr == "ETH" && address(this).balance > 0) || 
            (maxIACurr != "ETH" && erc20.balanceOf(address(this)) > 0))
                p1.triggerExternalLiquidityTrade();
            
        }
    }

    /**
     * @dev Creates External excess liquidity trading  
     * order for a given currency and a given balance.
     * @param curr Currency Asset to Sell
     * @param minIACurr Investment Asset to Buy  
     * @param amount Amount of Currency Asset to Sell
     */  
    function _externalExcessLiquiditySwap(
        bytes4 curr,
        bytes4 minIACurr,
        uint256 amount
    )
        internal
        returns (bool trigger)
    {
        uint intermediaryEth;
        Exchange exchange;
        IERC20 erc20;
        uint ethVol = pd.ethVolumeLimit();
        if (curr == minIACurr) {
            p1.transferCurrencyAsset(curr, amount);
        } else if (curr == "ETH" && minIACurr != "ETH") {
            
            exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(minIACurr)));
            if (amount > (address(exchange).balance.mul(ethVol)).div(100)) { // 4% ETH volume limit 
                amount = (address(exchange).balance.mul(ethVol)).div(100);
                trigger = true;
            }
            p1.transferCurrencyAsset(curr, amount);
            exchange.ethToTokenSwapInput.value(amount)
            (exchange.getEthToTokenInputPrice(amount).mul(995).div(1000), pd.uniswapDeadline().add(now));    
        } else if (curr != "ETH" && minIACurr == "ETH") {
            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            erc20 = IERC20(pd.getCurrencyAssetAddress(curr));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);

            if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) { 
                intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                intermediaryEth = exchange.getTokenToEthInputPrice(amount);
                trigger = true;
            }
            p1.transferCurrencyAsset(curr, amount);
            // erc20.decreaseAllowance(address(exchange), erc20.allowance(address(this), address(exchange)));
            erc20.approve(address(exchange), amount);
            
            exchange.tokenToEthSwapInput(amount, (
                intermediaryEth.mul(995)).div(1000), pd.uniswapDeadline().add(now));   
        } else {
            
            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);

            if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) { 
                intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                trigger = true;
            }
            
            Exchange tmp = Exchange(factory.getExchange(
                pd.getInvestmentAssetAddress(minIACurr))); // minIACurr exchange

            if (intermediaryEth > address(tmp).balance.mul(ethVol).div(100)) { 
                intermediaryEth = address(tmp).balance.mul(ethVol).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                trigger = true;   
            }
            p1.transferCurrencyAsset(curr, amount);
            erc20 = IERC20(pd.getCurrencyAssetAddress(curr));
            erc20.approve(address(exchange), amount);
            
            exchange.tokenToTokenSwapInput(amount, (tmp.getEthToTokenInputPrice(
                intermediaryEth).mul(995)).div(1000), (intermediaryEth.mul(995)).div(1000), 
                    pd.uniswapDeadline().add(now), pd.getInvestmentAssetAddress(minIACurr));
        }
    }

    /** 
     * @dev insufficient liquidity swap  
     * for a given currency and a given balance.
     * @param curr Currency Asset to buy
     * @param maxIACurr Investment Asset to sell
     * @param amount Amount of Investment Asset to sell
     */ 
    function _externalInsufficientLiquiditySwap(
        bytes4 curr,
        bytes4 maxIACurr,
        uint256 amount
    ) 
        internal
        returns (bool trigger)
    {   

        Exchange exchange;
        IERC20 erc20;
        uint intermediaryEth;
        // uint ethVol = pd.ethVolumeLimit();
        if (curr == maxIACurr) {
            _transferInvestmentAsset(curr, ms.getLatestAddress("P1"), amount);
        } else if (curr == "ETH" && maxIACurr != "ETH") { 
            exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(maxIACurr)));
            intermediaryEth = exchange.getEthToTokenInputPrice(amount);


            if (amount > (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100)) { 
                amount = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);
                // amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                intermediaryEth = exchange.getEthToTokenInputPrice(amount);
                trigger = true;
            }
            
            erc20 = IERC20(pd.getCurrencyAssetAddress(maxIACurr));
            if (intermediaryEth > erc20.balanceOf(address(this))) {
                intermediaryEth = erc20.balanceOf(address(this));
            }
            // erc20.decreaseAllowance(address(exchange), erc20.allowance(address(this), address(exchange)));
            erc20.approve(address(exchange), intermediaryEth);
            exchange.tokenToEthTransferInput(intermediaryEth, (
                exchange.getTokenToEthInputPrice(intermediaryEth).mul(995)).div(1000), 
                pd.uniswapDeadline().add(now), address(p1)); 

        } else if (curr != "ETH" && maxIACurr == "ETH") {
            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);
            if (intermediaryEth > address(this).balance)
                intermediaryEth = address(this).balance;
            if (intermediaryEth > (address(exchange).balance.mul
            (pd.ethVolumeLimit())).div(100)) { // 4% ETH volume limit 
                intermediaryEth = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);
                trigger = true;
            }
            exchange.ethToTokenTransferInput.value(intermediaryEth)((exchange.getEthToTokenInputPrice(
                intermediaryEth).mul(995)).div(1000), pd.uniswapDeadline().add(now), address(p1));   
        } else {
            address currAdd = pd.getCurrencyAssetAddress(curr);
            exchange = Exchange(factory.getExchange(currAdd));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);
            if (intermediaryEth > (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100)) { 
                intermediaryEth = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);
                trigger = true;
            }
            Exchange tmp = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(maxIACurr)));

            if (intermediaryEth > address(tmp).balance.mul(pd.ethVolumeLimit()).div(100)) { 
                intermediaryEth = address(tmp).balance.mul(pd.ethVolumeLimit()).div(100);
                // amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                trigger = true;
            }

            uint maxIAToSell = tmp.getEthToTokenInputPrice(intermediaryEth);

            erc20 = IERC20(pd.getInvestmentAssetAddress(maxIACurr));
            uint maxIABal = erc20.balanceOf(address(this));
            if (maxIAToSell > maxIABal) {
                maxIAToSell = maxIABal;
                intermediaryEth = tmp.getTokenToEthInputPrice(maxIAToSell);
                // amount = exchange.getEthToTokenInputPrice(intermediaryEth);
            }
            amount = exchange.getEthToTokenInputPrice(intermediaryEth);
            erc20.approve(address(tmp), maxIAToSell);
            tmp.tokenToTokenTransferInput(maxIAToSell, (
                amount.mul(995)).div(1000), (
                    intermediaryEth), pd.uniswapDeadline().add(now), address(p1), currAdd);
        }
    }

    /** 
     * @dev Transfers ERC20 investment asset from this Pool to another Pool.
     */ 
    function _upgradeInvestmentPool(
        bytes4 _curr,
        address _newPoolAddress
    ) 
        internal
    {
        IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
        if (erc20.balanceOf(address(this)) > 0)
            require(erc20.transfer(_newPoolAddress, erc20.balanceOf(address(this))));
    }
}

// File: nexusmutual-contracts/contracts/Pool1.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;








contract Pool1 is usingOraclize, Iupgradable {
    using SafeMath for uint;

    Quotation internal q2;
    NXMToken internal tk;
    TokenController internal tc;
    TokenFunctions internal tf;
    Pool2 internal p2;
    PoolData internal pd;
    MCR internal m1;
    Claims public c1;
    TokenData internal td;
    bool internal locked;

    uint internal constant DECIMAL1E18 = uint(10) ** 18;
    // uint internal constant PRICE_STEP = uint(1000) * DECIMAL1E18;

    event Apiresult(address indexed sender, string msg, bytes32 myid);
    event Payout(address indexed to, uint coverId, uint tokens);

    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    function () external payable {} //solhint-disable-line

    /**
     * @dev Pays out the sum assured in case a claim is accepted
     * @param coverid Cover Id.
     * @param claimid Claim Id.
     * @return succ true if payout is successful, false otherwise. 
     */ 
    function sendClaimPayout(
        uint coverid,
        uint claimid,
        uint sumAssured,
        address payable coverHolder,
        bytes4 coverCurr
    )
        external
        onlyInternal
        noReentrancy
        returns(bool succ)
    {
        
        uint sa = sumAssured.div(DECIMAL1E18);
        bool check;
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));

        //Payout
        if (coverCurr == "ETH" && address(this).balance >= sumAssured) {
            // check = _transferCurrencyAsset(coverCurr, coverHolder, sumAssured);
            coverHolder.transfer(sumAssured);
            check = true;
        } else if (coverCurr == "DAI" && erc20.balanceOf(address(this)) >= sumAssured) {
            erc20.transfer(coverHolder, sumAssured);
            check = true;
        }
        
        if (check == true) {
            q2.removeSAFromCSA(coverid, sa);
            pd.changeCurrencyAssetVarMin(coverCurr, 
                pd.getCurrencyAssetVarMin(coverCurr).sub(sumAssured));
            emit Payout(coverHolder, coverid, sumAssured);
            succ = true;
        } else {
            c1.setClaimStatus(claimid, 12);
        }
        _triggerExternalLiquidityTrade();
        // p2.internalLiquiditySwap(coverCurr);

        tf.burnStakerLockedToken(coverid, coverCurr, sumAssured);
    }

    /**
     * @dev to trigger external liquidity trade
     */
    function triggerExternalLiquidityTrade() external onlyInternal {
        _triggerExternalLiquidityTrade();
    }

    ///@dev Oraclize call to close emergency pause.
    function closeEmergencyPause(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 300000);
        _saveApiDetails(myid, "EP", 0);
    }

    /// @dev Calls the Oraclize Query to close a given Claim after a given period of time.
    /// @param id Claim Id to be closed
    /// @param time Time (in seconds) after which Claims assessment voting needs to be closed
    function closeClaimsOraclise(uint id, uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 3000000);
        _saveApiDetails(myid, "CLA", id);
    }

    /// @dev Calls Oraclize Query to expire a given Cover after a given period of time.
    /// @param id Quote Id to be expired
    /// @param time Time (in seconds) after which the cover should be expired
    function closeCoverOraclise(uint id, uint64 time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", strConcat(
            "http://a1.nexusmutual.io/api/Claims/closeClaim_hash/", uint2str(id)), 1000000);
        _saveApiDetails(myid, "COV", id);
    }

    /// @dev Calls the Oraclize Query to initiate MCR calculation.
    /// @param time Time (in milliseconds) after which the next MCR calculation should be initiated
    function mcrOraclise(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(3, time, "URL", "https://api.nexusmutual.io/postMCR/M1", 0);
        _saveApiDetails(myid, "MCR", 0);
    }

    /// @dev Calls the Oraclize Query in case MCR calculation fails.
    /// @param time Time (in seconds) after which the next MCR calculation should be initiated
    function mcrOracliseFail(uint id, uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 1000000);
        _saveApiDetails(myid, "MCRF", id);
    }

    /// @dev Oraclize call to update investment asset rates.
    function saveIADetailsOracalise(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(3, time, "URL", "https://api.nexusmutual.io/saveIADetails/M1", 0);
        _saveApiDetails(myid, "IARB", 0);
    }
    
    /**
     * @dev Transfers all assest (i.e ETH balance, Currency Assest) from old Pool to new Pool
     * @param newPoolAddress Address of the new Pool
     */
    function upgradeCapitalPool(address payable newPoolAddress) external noReentrancy onlyInternal {
        for (uint64 i = 1; i < pd.getAllCurrenciesLen(); i++) {
            bytes4 caName = pd.getCurrenciesByIndex(i);
            _upgradeCapitalPool(caName, newPoolAddress);
        }
        if (address(this).balance > 0) {
            Pool1 newP1 = Pool1(newPoolAddress);
            newP1.sendEther.value(address(this).balance)();
        }
    }

    /**
     * @dev Iupgradable Interface to update dependent contract address
     */
    function changeDependentContractAddress() public {
        m1 = MCR(ms.getLatestAddress("MC"));
        tk = NXMToken(ms.tokenAddress());
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tc = TokenController(ms.getLatestAddress("TC"));
        pd = PoolData(ms.getLatestAddress("PD"));
        q2 = Quotation(ms.getLatestAddress("QT"));
        p2 = Pool2(ms.getLatestAddress("P2"));
        c1 = Claims(ms.getLatestAddress("CL"));
        td = TokenData(ms.getLatestAddress("TD"));
    }

    function sendEther() public payable {
        
    }

    /**
     * @dev transfers currency asset to an address
     * @param curr is the currency of currency asset to transfer
     * @param amount is amount of currency asset to transfer
     * @return boolean to represent success or failure
     */
    function transferCurrencyAsset(
        bytes4 curr,
        uint amount
    )
        public
        onlyInternal
        noReentrancy
        returns(bool)
    {
    
        return _transferCurrencyAsset(curr, amount);
    } 

    /// @dev Handles callback of external oracle query.
    function __callback(bytes32 myid, string memory result) public {
        result; //silence compiler warning
        // owner will be removed from production build
        ms.delegateCallBack(myid);
    }

    /// @dev Enables user to purchase cover with funding in ETH.
    /// @param smartCAdd Smart Contract Address
    function makeCoverBegin(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        isMember
        checkPause
        payable
    {
        require(msg.value == coverDetails[1]);
        q2.verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }

    /**
     * @dev Enables user to purchase cover via currency asset eg DAI
     */ 
    function makeCoverUsingCA(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) 
        public
        isMember
        checkPause
    {
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));
        require(erc20.transferFrom(msg.sender, address(this), coverDetails[1]), "Transfer failed");
        q2.verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }

    /// @dev Enables user to purchase NXM at the current token price.
    function buyToken() public payable isMember checkPause returns(bool success) {
        require(msg.value > 0);
        uint tokenPurchased = _getToken(address(this).balance, msg.value);
        tc.mint(msg.sender, tokenPurchased);
        success = true;
    }

    /// @dev Sends a given amount of Ether to a given address.
    /// @param amount amount (in wei) to send.
    /// @param _add Receiver's address.
    /// @return succ True if transfer is a success, otherwise False.
    function transferEther(uint amount, address payable _add) public noReentrancy checkPause returns(bool succ) {
        require(ms.checkIsAuthToGoverned(msg.sender), "Not authorized to Govern");
        succ = _add.send(amount);
    }

    /**
     * @dev Allows selling of NXM for ether.
     * Seller first needs to give this contract allowance to
     * transfer/burn tokens in the NXMToken contract
     * @param  _amount Amount of NXM to sell
     * @return success returns true on successfull sale
     */
    function sellNXMTokens(uint _amount) public isMember noReentrancy checkPause returns(bool success) {
        require(tk.balanceOf(msg.sender) >= _amount, "Not enough balance");
        require(!tf.isLockedForMemberVote(msg.sender), "Member voted");
        require(_amount <= m1.getMaxSellTokens(), "exceeds maximum token sell limit");
        uint sellingPrice = _getWei(_amount);
        tc.burnFrom(msg.sender, _amount);
        msg.sender.transfer(sellingPrice);
        success = true;
    }

    /**
     * @dev gives the investment asset balance
     * @return investment asset balance
     */
    function getInvestmentAssetBalance() public view returns (uint balance) {
        IERC20 erc20;
        uint currTokens;
        for (uint i = 1; i < pd.getInvestmentCurrencyLen(); i++) {
            bytes4 currency = pd.getInvestmentCurrencyByIndex(i);
            erc20 = IERC20(pd.getInvestmentAssetAddress(currency));
            currTokens = erc20.balanceOf(address(p2));
            if (pd.getIAAvgRate(currency) > 0)
                balance = balance.add((currTokens.mul(100)).div(pd.getIAAvgRate(currency)));
        }

        balance = balance.add(address(p2).balance);
    }

    /**
     * @dev Returns the amount of wei a seller will get for selling NXM
     * @param amount Amount of NXM to sell
     * @return weiToPay Amount of wei the seller will get
     */
    function getWei(uint amount) public view returns(uint weiToPay) {
        return _getWei(amount);
    }

    /**
     * @dev Returns the amount of token a buyer will get for corresponding wei
     * @param weiPaid Amount of wei 
     * @return tokenToGet Amount of tokens the buyer will get
     */
    function getToken(uint weiPaid) public view returns(uint tokenToGet) {
        return _getToken((address(this).balance).add(weiPaid), weiPaid);
    }

    /**
     * @dev to trigger external liquidity trade
     */
    function _triggerExternalLiquidityTrade() internal {
        if (now > pd.lastLiquidityTradeTrigger().add(pd.liquidityTradeCallbackTime())) {
            pd.setLastLiquidityTradeTrigger();
            bytes32 myid = _oraclizeQuery(4, pd.liquidityTradeCallbackTime(), "URL", "", 300000);
            _saveApiDetails(myid, "ULT", 0);
        }
    }

    /**
     * @dev Returns the amount of wei a seller will get for selling NXM
     * @param _amount Amount of NXM to sell
     * @return weiToPay Amount of wei the seller will get
     */
    function _getWei(uint _amount) internal view returns(uint weiToPay) {
        uint tokenPrice;
        uint weiPaid;
        uint tokenSupply = tk.totalSupply();
        uint vtp;
        uint mcrFullperc;
        uint vFull;
        uint mcrtp;
        (mcrFullperc, , vFull, ) = pd.getLastMCR();
        (vtp, ) = m1.calVtpAndMCRtp();

        while (_amount > 0) {
            mcrtp = (mcrFullperc.mul(vtp)).div(vFull);
            tokenPrice = m1.calculateStepTokenPrice("ETH", mcrtp);
            tokenPrice = (tokenPrice.mul(975)).div(1000); //97.5%
            if (_amount <= td.priceStep().mul(DECIMAL1E18)) {
                weiToPay = weiToPay.add((tokenPrice.mul(_amount)).div(DECIMAL1E18));
                break;
            } else {
                _amount = _amount.sub(td.priceStep().mul(DECIMAL1E18));
                tokenSupply = tokenSupply.sub(td.priceStep().mul(DECIMAL1E18));
                weiPaid = (tokenPrice.mul(td.priceStep().mul(DECIMAL1E18))).div(DECIMAL1E18);
                vtp = vtp.sub(weiPaid);
                weiToPay = weiToPay.add(weiPaid);
            }
        }
    }

    /**
     * @dev gives the token
     * @param _poolBalance is the pool balance
     * @param _weiPaid is the amount paid in wei
     * @return the token to get
     */
    function _getToken(uint _poolBalance, uint _weiPaid) internal view returns(uint tokenToGet) {
        uint tokenPrice;
        uint superWeiLeft = (_weiPaid).mul(DECIMAL1E18);
        uint tempTokens;
        uint superWeiSpent;
        uint tokenSupply = tk.totalSupply();
        uint vtp;
        uint mcrFullperc;   
        uint vFull;
        uint mcrtp;
        (mcrFullperc, , vFull, ) = pd.getLastMCR();
        (vtp, ) = m1.calculateVtpAndMCRtp((_poolBalance).sub(_weiPaid));

        require(m1.calculateTokenPrice("ETH") > 0, "Token price can not be zero");
        while (superWeiLeft > 0) {
            mcrtp = (mcrFullperc.mul(vtp)).div(vFull);
            tokenPrice = m1.calculateStepTokenPrice("ETH", mcrtp);            
            tempTokens = superWeiLeft.div(tokenPrice);
            if (tempTokens <= td.priceStep().mul(DECIMAL1E18)) {
                tokenToGet = tokenToGet.add(tempTokens);
                break;
            } else {
                tokenToGet = tokenToGet.add(td.priceStep().mul(DECIMAL1E18));
                tokenSupply = tokenSupply.add(td.priceStep().mul(DECIMAL1E18));
                superWeiSpent = td.priceStep().mul(DECIMAL1E18).mul(tokenPrice);
                superWeiLeft = superWeiLeft.sub(superWeiSpent);
                vtp = vtp.add((td.priceStep().mul(DECIMAL1E18).mul(tokenPrice)).div(DECIMAL1E18));
            }
        }
    }

    /** 
     * @dev Save the details of the Oraclize API.
     * @param myid Id return by the oraclize query.
     * @param _typeof type of the query for which oraclize call is made.
     * @param id ID of the proposal, quote, cover etc. for which oraclize call is made.
     */ 
    function _saveApiDetails(bytes32 myid, bytes4 _typeof, uint id) internal {
        pd.saveApiDetails(myid, _typeof, id);
        pd.addInAllApiCall(myid);
    }

    /**
     * @dev transfers currency asset
     * @param _curr is currency of asset to transfer
     * @param _amount is the amount to be transferred
     * @return boolean representing the success of transfer
     */
    function _transferCurrencyAsset(bytes4 _curr, uint _amount) internal returns(bool succ) {
        if (_curr == "ETH") {
            if (address(this).balance < _amount)
                _amount = address(this).balance;
            p2.sendEther.value(_amount)();
            succ = true;
        } else {
            IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr)); //solhint-disable-line
            if (erc20.balanceOf(address(this)) < _amount) 
                _amount = erc20.balanceOf(address(this));
            require(erc20.transfer(address(p2), _amount)); 
            succ = true;
            
        }
    } 

    /** 
     * @dev Transfers ERC20 Currency asset from this Pool to another Pool on upgrade.
     */ 
    function _upgradeCapitalPool(
        bytes4 _curr,
        address _newPoolAddress
    ) 
        internal
    {
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr));
        if (erc20.balanceOf(address(this)) > 0)
            require(erc20.transfer(_newPoolAddress, erc20.balanceOf(address(this))));
    }

    /**
     * @dev oraclize query
     * @param paramCount is number of paramters passed
     * @param timestamp is the current timestamp
     * @param datasource in concern
     * @param arg in concern
     * @param gasLimit required for query
     * @return id of oraclize query
     */
    function _oraclizeQuery(
        uint paramCount,
        uint timestamp,
        string memory datasource,
        string memory arg,
        uint gasLimit
    ) 
        internal
        returns (bytes32 id)
    {
        if (paramCount == 4) {
            id = oraclize_query(timestamp, datasource, arg, gasLimit);   
        } else if (paramCount == 3) {
            id = oraclize_query(timestamp, datasource, arg);   
        } else {
            id = oraclize_query(datasource, arg);
        }
    }
}

// File: nexusmutual-contracts/contracts/MCR.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;









contract MCR is Iupgradable {
    using SafeMath for uint;

    Pool1 internal p1;
    PoolData internal pd;
    NXMToken internal tk;
    QuotationData internal qd;
    MemberRoles internal mr;
    TokenData internal td;
    ProposalCategory internal proposalCategory;

    uint private constant DECIMAL1E18 = uint(10) ** 18;
    uint private constant DECIMAL1E05 = uint(10) ** 5;
    uint private constant DECIMAL1E19 = uint(10) ** 19;
    uint private constant minCapFactor = uint(10) ** 21;

    uint public variableMincap;
    uint public dynamicMincapThresholdx100 = 13000;
    uint public dynamicMincapIncrementx100 = 100;

    event MCREvent(
        uint indexed date,
        uint blockNumber,
        bytes4[] allCurr,
        uint[] allCurrRates,
        uint mcrEtherx100,
        uint mcrPercx100,
        uint vFull
    );

    /** 
     * @dev Adds new MCR data.
     * @param mcrP  Minimum Capital Requirement in percentage.
     * @param vF Pool1 fund value in Ether used in the last full daily calculation of the Capital model.
     * @param onlyDate  Date(yyyymmdd) at which MCR details are getting added.
     */ 
    function addMCRData(
        uint mcrP,
        uint mcrE,
        uint vF,
        bytes4[] calldata curr,
        uint[] calldata _threeDayAvg,
        uint64 onlyDate
    )
        external
        checkPause
    {
        require(proposalCategory.constructorCheck());
        require(pd.isnotarise(msg.sender));
        if (mr.launched() && pd.capReached() != 1) {
            
            if (mcrP >= 10000)
                pd.setCapReached(1);  

        }
        uint len = pd.getMCRDataLength();
        _addMCRData(len, onlyDate, curr, mcrE, mcrP, vF, _threeDayAvg);
    }

    /**
     * @dev Adds MCR Data for last failed attempt.
     */  
    function addLastMCRData(uint64 date) external checkPause  onlyInternal {
        uint64 lastdate = uint64(pd.getLastMCRDate());
        uint64 failedDate = uint64(date);
        if (failedDate >= lastdate) {
            uint mcrP;
            uint mcrE;
            uint vF;
            (mcrP, mcrE, vF, ) = pd.getLastMCR();
            uint len = pd.getAllCurrenciesLen();
            pd.pushMCRData(mcrP, mcrE, vF, date);
            for (uint j = 0; j < len; j++) {
                bytes4 currName = pd.getCurrenciesByIndex(j);
                pd.updateCAAvgRate(currName, pd.getCAAvgRate(currName));
            }

            emit MCREvent(date, block.number, new bytes4[](0), new uint[](0), mcrE, mcrP, vF);
            // Oraclize call for next MCR calculation
            _callOracliseForMCR();
        }
    }

    /**
     * @dev Iupgradable Interface to update dependent contract address
     */
    function changeDependentContractAddress() public onlyInternal {
        qd = QuotationData(ms.getLatestAddress("QD"));
        p1 = Pool1(ms.getLatestAddress("P1"));
        pd = PoolData(ms.getLatestAddress("PD"));
        tk = NXMToken(ms.tokenAddress());
        mr = MemberRoles(ms.getLatestAddress("MR"));
        td = TokenData(ms.getLatestAddress("TD"));
        proposalCategory = ProposalCategory(ms.getLatestAddress("PC"));
    }

    /** 
     * @dev Gets total sum assured(in ETH).
     * @return amount of sum assured
     */  
    function getAllSumAssurance() public view returns(uint amount) {
        uint len = pd.getAllCurrenciesLen();
        for (uint i = 0; i < len; i++) {
            bytes4 currName = pd.getCurrenciesByIndex(i);
            if (currName == "ETH") {
                amount = amount.add(qd.getTotalSumAssured(currName));
            } else {
                if (pd.getCAAvgRate(currName) > 0)
                    amount = amount.add((qd.getTotalSumAssured(currName).mul(100)).div(pd.getCAAvgRate(currName)));
            }
        }
    }

    /**
     * @dev Calculates V(Tp) and MCR%(Tp), i.e, Pool Fund Value in Ether 
     * and MCR% used in the Token Price Calculation.
     * @return vtp  Pool Fund Value in Ether used for the Token Price Model
     * @return mcrtp MCR% used in the Token Price Model. 
     */ 
    function _calVtpAndMCRtp(uint poolBalance) public view returns(uint vtp, uint mcrtp) {
        vtp = 0;
        IERC20 erc20;
        uint currTokens = 0;
        uint i;
        for (i = 1; i < pd.getAllCurrenciesLen(); i++) {
            bytes4 currency = pd.getCurrenciesByIndex(i);
            erc20 = IERC20(pd.getCurrencyAssetAddress(currency));
            currTokens = erc20.balanceOf(address(p1));
            if (pd.getCAAvgRate(currency) > 0)
                vtp = vtp.add((currTokens.mul(100)).div(pd.getCAAvgRate(currency)));
        }

        vtp = vtp.add(poolBalance).add(p1.getInvestmentAssetBalance());
        uint mcrFullperc;
        uint vFull;
        (mcrFullperc, , vFull, ) = pd.getLastMCR();
        if (vFull > 0) {
            mcrtp = (mcrFullperc.mul(vtp)).div(vFull);
        }
    }

    /**
     * @dev Calculates the Token Price of NXM in a given currency.
     * @param curr Currency name.
     
     */
    function calculateStepTokenPrice(
        bytes4 curr,
        uint mcrtp
    ) 
        public
        view
        onlyInternal
        returns(uint tokenPrice)
    {
        return _calculateTokenPrice(curr, mcrtp);
    }

    /**
     * @dev Calculates the Token Price of NXM in a given currency 
     * with provided token supply for dynamic token price calculation
     * @param curr Currency name.
     */ 
    function calculateTokenPrice (bytes4 curr) public view returns(uint tokenPrice) {
        uint mcrtp;
        (, mcrtp) = _calVtpAndMCRtp(address(p1).balance); 
        return _calculateTokenPrice(curr, mcrtp);
    }
    
    function calVtpAndMCRtp() public view returns(uint vtp, uint mcrtp) {
        return _calVtpAndMCRtp(address(p1).balance);
    }

    function calculateVtpAndMCRtp(uint poolBalance) public view returns(uint vtp, uint mcrtp) {
        return _calVtpAndMCRtp(poolBalance);
    }

    function getThresholdValues(uint vtp, uint vF, uint totalSA, uint minCap) public view returns(uint lowerThreshold, uint upperThreshold)
    {
        minCap = (minCap.mul(minCapFactor)).add(variableMincap);
        uint lower = 0;
        if (vtp >= vF) {
                upperThreshold = vtp.mul(120).mul(100).div((minCap));     //Max Threshold = [MAX(Vtp, Vfull) x 120] / mcrMinCap
            } else {
                upperThreshold = vF.mul(120).mul(100).div((minCap));
            }

            if (vtp > 0) {
                lower = totalSA.mul(DECIMAL1E18).mul(pd.shockParameter()).div(100);
                if(lower < minCap.mul(11).div(10))
                    lower = minCap.mul(11).div(10);
            }
            if (lower > 0) {                                       //Min Threshold = [Vtp / MAX(TotalActiveSA x ShockParameter, mcrMinCap x 1.1)] x 100
                lowerThreshold = vtp.mul(100).mul(100).div(lower);
            }
    }

    /**
     * @dev Gets max numbers of tokens that can be sold at the moment.
     */ 
    function getMaxSellTokens() public view returns(uint maxTokens) {
        uint baseMin = pd.getCurrencyAssetBaseMin("ETH");
        uint maxTokensAccPoolBal;
        if (address(p1).balance > baseMin.mul(50).div(100)) {
            maxTokensAccPoolBal = address(p1).balance.sub(
            (baseMin.mul(50)).div(100));        
        }
        maxTokensAccPoolBal = (maxTokensAccPoolBal.mul(DECIMAL1E18)).div(
            (calculateTokenPrice("ETH").mul(975)).div(1000));
        uint lastMCRPerc = pd.getLastMCRPerc();
        if (lastMCRPerc > 10000)
            maxTokens = (((uint(lastMCRPerc).sub(10000)).mul(2000)).mul(DECIMAL1E18)).div(10000);
        if (maxTokens > maxTokensAccPoolBal)
            maxTokens = maxTokensAccPoolBal;     
    }

    /**
     * @dev Gets Uint Parameters of a code
     * @param code whose details we want
     * @return string value of the code
     * @return associated amount (time or perc or value) to the code
     */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {
        codeVal = code;
        if (code == "DMCT") {
            val = dynamicMincapThresholdx100;

        } else if (code == "DMCI") {

            val = dynamicMincapIncrementx100;

        }
            
    }

    /**
     * @dev Updates Uint Parameters of a code
     * @param code whose details we want to update
     * @param val value to set
     */
    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "DMCT") {
           dynamicMincapThresholdx100 = val;

        } else if (code == "DMCI") {

            dynamicMincapIncrementx100 = val;

        }
         else {
            revert("Invalid param code");
        }
            
    }

    /** 
     * @dev Calls oraclize query to calculate MCR details after 24 hours.
     */ 
    function _callOracliseForMCR() internal {
        p1.mcrOraclise(pd.mcrTime());
    }

    /**
     * @dev Calculates the Token Price of NXM in a given currency 
     * with provided token supply for dynamic token price calculation
     * @param _curr Currency name.  
     * @return tokenPrice Token price.
     */ 
    function _calculateTokenPrice(
        bytes4 _curr,
        uint mcrtp
    )
        internal
        view
        returns(uint tokenPrice)
    {
        uint getA;
        uint getC;
        uint getCAAvgRate;
        uint tokenExponentValue = td.tokenExponent();
        // uint max = (mcrtp.mul(mcrtp).mul(mcrtp).mul(mcrtp));
        uint max = mcrtp ** tokenExponentValue;
        uint dividingFactor = tokenExponentValue.mul(4); 
        (getA, getC, getCAAvgRate) = pd.getTokenPriceDetails(_curr);
        uint mcrEth = pd.getLastMCREther();
        getC = getC.mul(DECIMAL1E18);
        tokenPrice = (mcrEth.mul(DECIMAL1E18).mul(max).div(getC)).div(10 ** dividingFactor);
        tokenPrice = tokenPrice.add(getA.mul(DECIMAL1E18).div(DECIMAL1E05));
        tokenPrice = tokenPrice.mul(getCAAvgRate * 10); 
        tokenPrice = (tokenPrice).div(10**3);
    } 
    
    /**
     * @dev Adds MCR Data. Checks if MCR is within valid 
     * thresholds in order to rule out any incorrect calculations 
     */  
    function _addMCRData(
        uint len,
        uint64 newMCRDate,
        bytes4[] memory curr,
        uint mcrE,
        uint mcrP,
        uint vF,
        uint[] memory _threeDayAvg
    ) 
        internal
    {
        uint vtp = 0;
        uint lowerThreshold = 0;
        uint upperThreshold = 0;
        if (len > 1) {
            (vtp, ) = _calVtpAndMCRtp(address(p1).balance);
            (lowerThreshold, upperThreshold) = getThresholdValues(vtp, vF, getAllSumAssurance(), pd.minCap());

        }
        if(mcrP > dynamicMincapThresholdx100)
            variableMincap =  (variableMincap.mul(dynamicMincapIncrementx100.add(10000)).add(minCapFactor.mul(pd.minCap().mul(dynamicMincapIncrementx100)))).div(10000);


        // Explanation for above formula :- 
        // actual formula -> variableMinCap =  variableMinCap + (variableMinCap+minCap)*dynamicMincapIncrement/100
        // Implemented formula is simplified form of actual formula.
        // Let consider above formula as b = b + (a+b)*c/100
        // here, dynamicMincapIncrement is in x100 format. 
        // so b+(a+b)*cx100/10000 can be written as => (10000.b + b.cx100 + a.cx100)/10000.
        // It can further simplify to (b.(10000+cx100) + a.cx100)/10000.
        if (len == 1 || (mcrP) >= lowerThreshold 
            && (mcrP) <= upperThreshold) {
            vtp = pd.getLastMCRDate(); // due to stack to deep error,we are reusing already declared variable
            pd.pushMCRData(mcrP, mcrE, vF, newMCRDate);
            for (uint i = 0; i < curr.length; i++) {
                pd.updateCAAvgRate(curr[i], _threeDayAvg[i]);
            }
            emit MCREvent(newMCRDate, block.number, curr, _threeDayAvg, mcrE, mcrP, vF);
            // Oraclize call for next MCR calculation
            if (vtp < newMCRDate) {
                _callOracliseForMCR();
            }
        } else {
            p1.mcrOracliseFail(newMCRDate, pd.mcrFailTime());
        }
    }

}

// File: nexusmutual-contracts/contracts/Claims.sol

/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;





contract Claims is Iupgradable {
    using SafeMath for uint;

    
    TokenFunctions internal tf;
    NXMToken internal tk;
    TokenController internal tc;
    ClaimsReward internal cr;
    Pool1 internal p1;
    ClaimsData internal cd;
    TokenData internal td;
    PoolData internal pd;
    Pool2 internal p2;
    QuotationData internal qd;
    MCR internal m1;

    uint private constant DECIMAL1E18 = uint(10) ** 18;
    
    /**
     * @dev Sets the status of claim using claim id.
     * @param claimId claim id.
     * @param stat status to be set.
     */ 
    function setClaimStatus(uint claimId, uint stat) external onlyInternal {
        _setClaimStatus(claimId, stat);
    }

    /**
     * @dev Gets claim details of claim id = pending claim start + given index
     */ 
    function getClaimFromNewStart(
        uint index
    )
        external 
        view 
        returns (
            uint coverId,
            uint claimId,
            int8 voteCA,
            int8 voteMV,
            uint statusnumber
        ) 
    {
        (coverId, claimId, voteCA, voteMV, statusnumber) = cd.getClaimFromNewStart(index, msg.sender);
        // status = rewardStatus[statusnumber].claimStatusDesc;
    }

    /**
     * @dev Gets details of a claim submitted by the calling user, at a given index
     */
    function getUserClaimByIndex(
        uint index
    )
        external
        view 
        returns(
            uint status,
            uint coverId,
            uint claimId
        )
    {
        uint statusno;
        (statusno, coverId, claimId) = cd.getUserClaimByIndex(index, msg.sender);
        status = statusno;
    }

    /**
     * @dev Gets details of a given claim id.
     * @param _claimId Claim Id.
     * @return status Current status of claim id
     * @return finalVerdict Decision made on the claim, 1 -> acceptance, -1 -> denial
     * @return claimOwner Address through which claim is submitted
     * @return coverId Coverid associated with the claim id
     */
    function getClaimbyIndex(uint _claimId) external view returns (
        uint claimId,
        uint status,
        int8 finalVerdict,
        address claimOwner,
        uint coverId
    )
    {
        uint stat;
        claimId = _claimId;
        (, coverId, finalVerdict, stat, , ) = cd.getClaim(_claimId);
        claimOwner = qd.getCoverMemberAddress(coverId);
        status = stat;
    }

    /**
     * @dev Calculates total amount that has been used to assess a claim.
     * Computaion:Adds acceptCA(tokens used for voting in favor of a claim)
     * denyCA(tokens used for voting against a claim) *  current token price.
     * @param claimId Claim Id.
     * @param member Member type 0 -> Claim Assessors, else members.
     * @return tokens Total Amount used in Claims assessment.
     */ 
    function getCATokens(uint claimId, uint member) external view returns(uint tokens) {
        uint coverId;
        (, coverId) = cd.getClaimCoverId(claimId);
        bytes4 curr = qd.getCurrencyOfCover(coverId);
        uint tokenx1e18 = m1.calculateTokenPrice(curr);
        uint accept;
        uint deny;
        if (member == 0) {
            (, accept, deny) = cd.getClaimsTokenCA(claimId);
        } else {
            (, accept, deny) = cd.getClaimsTokenMV(claimId);
        }
        tokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18); // amount (not in tokens)
    }

    /**
     * Iupgradable Interface to update dependent contract address
     */
    function changeDependentContractAddress() public onlyInternal {
        tk = NXMToken(ms.tokenAddress());
        td = TokenData(ms.getLatestAddress("TD"));
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tc = TokenController(ms.getLatestAddress("TC"));
        p1 = Pool1(ms.getLatestAddress("P1"));
        p2 = Pool2(ms.getLatestAddress("P2"));
        pd = PoolData(ms.getLatestAddress("PD"));
        cr = ClaimsReward(ms.getLatestAddress("CR"));
        cd = ClaimsData(ms.getLatestAddress("CD"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        m1 = MCR(ms.getLatestAddress("MC"));
    }

    /**
     * @dev Updates the pending claim start variable,
     * the lowest claim id with a pending decision/payout.
     */ 
    function changePendingClaimStart() public onlyInternal {

        uint origstat;
        uint state12Count;
        uint pendingClaimStart = cd.pendingClaimStart();
        uint actualClaimLength = cd.actualClaimLength();
        for (uint i = pendingClaimStart; i < actualClaimLength; i++) {
            (, , , origstat, , state12Count) = cd.getClaim(i);

            if (origstat > 5 && ((origstat != 12) || (origstat == 12 && state12Count >= 60)))
                cd.setpendingClaimStart(i);
            else
                break;
        }
    }

    /**
     * @dev Submits a claim for a given cover note.
     * Adds claim to queue incase of emergency pause else directly submits the claim.
     * @param coverId Cover Id.
     */ 
    function submitClaim(uint coverId) public {
        address qadd = qd.getCoverMemberAddress(coverId);
        require(qadd == msg.sender);
        uint8 cStatus;
        (, cStatus, , , ) = qd.getCoverDetailsByCoverID2(coverId);
        require(cStatus != uint8(QuotationData.CoverStatus.ClaimSubmitted), "Claim already submitted");
        require(cStatus != uint8(QuotationData.CoverStatus.CoverExpired), "Cover already expired");
        if (ms.isPause() == false) {
            _addClaim(coverId, now, qadd);
        } else {
            cd.setClaimAtEmergencyPause(coverId, now, false);
            qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.Requested));
        }
    }

    /**
     * @dev Submits the Claims queued once the emergency pause is switched off.
     */
    function submitClaimAfterEPOff() public onlyInternal {
        uint lengthOfClaimSubmittedAtEP = cd.getLengthOfClaimSubmittedAtEP();
        uint firstClaimIndexToSubmitAfterEP = cd.getFirstClaimIndexToSubmitAfterEP();
        uint coverId;
        uint dateUpd;
        bool submit;
        address qadd;
        for (uint i = firstClaimIndexToSubmitAfterEP; i < lengthOfClaimSubmittedAtEP; i++) {
            (coverId, dateUpd, submit) = cd.getClaimOfEmergencyPauseByIndex(i);
            require(submit == false);
            qadd = qd.getCoverMemberAddress(coverId);
            _addClaim(coverId, dateUpd, qadd);
            cd.setClaimSubmittedAtEPTrue(i, true);
        }
        cd.setFirstClaimIndexToSubmitAfterEP(lengthOfClaimSubmittedAtEP);
    }

    /**
     * @dev Castes vote for members who have tokens locked under Claims Assessment
     * @param claimId  claim id.
     * @param verdict 1 for Accept,-1 for Deny.
     */ 
    function submitCAVote(uint claimId, int8 verdict) public isMemberAndcheckPause {
        require(checkVoteClosing(claimId) != 1); 
        require(cd.userClaimVotePausedOn(msg.sender).add(cd.pauseDaysCA()) < now);  
        uint tokens = tc.tokensLockedAtTime(msg.sender, "CLA", now.add(cd.claimDepositTime()));
        require(tokens > 0);
        uint stat;
        (, stat) = cd.getClaimStatusNumber(claimId);
        require(stat == 0);
        require(cd.getUserClaimVoteCA(msg.sender, claimId) == 0);
        td.bookCATokens(msg.sender);
        cd.addVote(msg.sender, tokens, claimId, verdict);
        cd.callVoteEvent(msg.sender, claimId, "CAV", tokens, now, verdict);
        uint voteLength = cd.getAllVoteLength();
        cd.addClaimVoteCA(claimId, voteLength);
        cd.setUserClaimVoteCA(msg.sender, claimId, voteLength);
        cd.setClaimTokensCA(claimId, verdict, tokens);
        tc.extendLockOf(msg.sender, "CLA", td.lockCADays());
        int close = checkVoteClosing(claimId);
        if (close == 1) {
            cr.changeClaimStatus(claimId);
        }
    }

    /**
     * @dev Submits a member vote for assessing a claim.
     * Tokens other than those locked under Claims
     * Assessment can be used to cast a vote for a given claim id.
     * @param claimId Selected claim id.
     * @param verdict 1 for Accept,-1 for Deny.
     */ 
    function submitMemberVote(uint claimId, int8 verdict) public isMemberAndcheckPause {
        require(checkVoteClosing(claimId) != 1);
        uint stat;
        uint tokens = tc.totalBalanceOf(msg.sender);
        (, stat) = cd.getClaimStatusNumber(claimId);
        require(stat >= 1 && stat <= 5);
        require(cd.getUserClaimVoteMember(msg.sender, claimId) == 0);
        cd.addVote(msg.sender, tokens, claimId, verdict);
        cd.callVoteEvent(msg.sender, claimId, "MV", tokens, now, verdict);
        tc.lockForMemberVote(msg.sender, td.lockMVDays());
        uint voteLength = cd.getAllVoteLength();
        cd.addClaimVotemember(claimId, voteLength);
        cd.setUserClaimVoteMember(msg.sender, claimId, voteLength);
        cd.setClaimTokensMV(claimId, verdict, tokens);
        int close = checkVoteClosing(claimId);
        if (close == 1) {
            cr.changeClaimStatus(claimId);
        }
    }

    /**
    * @dev Pause Voting of All Pending Claims when Emergency Pause Start.
    */ 
    function pauseAllPendingClaimsVoting() public onlyInternal {
        uint firstIndex = cd.pendingClaimStart();
        uint actualClaimLength = cd.actualClaimLength();
        for (uint i = firstIndex; i < actualClaimLength; i++) {
            if (checkVoteClosing(i) == 0) {
                uint dateUpd = cd.getClaimDateUpd(i);
                cd.setPendingClaimDetails(i, (dateUpd.add(cd.maxVotingTime())).sub(now), false);
            }
        }
    }

    /**
     * @dev Resume the voting phase of all Claims paused due to an emergency pause.
     */
    function startAllPendingClaimsVoting() public onlyInternal {
        uint firstIndx = cd.getFirstClaimIndexToStartVotingAfterEP();
        uint i;
        uint lengthOfClaimVotingPause = cd.getLengthOfClaimVotingPause();
        for (i = firstIndx; i < lengthOfClaimVotingPause; i++) {
            uint pendingTime;
            uint claimID;
            (claimID, pendingTime, ) = cd.getPendingClaimDetailsByIndex(i);
            uint pTime = (now.sub(cd.maxVotingTime())).add(pendingTime);
            cd.setClaimdateUpd(claimID, pTime);
            cd.setPendingClaimVoteStatus(i, true);
            uint coverid;
            (, coverid) = cd.getClaimCoverId(claimID);
            address qadd = qd.getCoverMemberAddress(coverid);
            tf.extendCNEPOff(qadd, coverid, pendingTime.add(cd.claimDepositTime()));
            p1.closeClaimsOraclise(claimID, uint64(pTime));
        }
        cd.setFirstClaimIndexToStartVotingAfterEP(i);
    }

    /**
     * @dev Checks if voting of a claim should be closed or not.
     * @param claimId Claim Id.
     * @return close 1 -> voting should be closed, 0 -> if voting should not be closed,
     * -1 -> voting has already been closed.
     */ 
    function checkVoteClosing(uint claimId) public view returns(int8 close) {
        close = 0;
        uint status;
        (, status) = cd.getClaimStatusNumber(claimId);
        uint dateUpd = cd.getClaimDateUpd(claimId);
        if (status == 12 && dateUpd.add(cd.payoutRetryTime()) < now) {
            if (cd.getClaimState12Count(claimId) < 60)
                close = 1;
        } 
        
        if (status > 5 && status != 12) {
            close = -1;
        }  else if (status != 12 && dateUpd.add(cd.maxVotingTime()) <= now) {
            close = 1;
        } else if (status != 12 && dateUpd.add(cd.minVotingTime()) >= now) {
            close = 0;
        } else if (status == 0 || (status >= 1 && status <= 5)) {
            close = _checkVoteClosingFinal(claimId, status);
        }
        
    }

    /**
     * @dev Checks if voting of a claim should be closed or not.
     * Internally called by checkVoteClosing method
     * for Claims whose status number is 0 or status number lie between 2 and 6.
     * @param claimId Claim Id.
     * @param status Current status of claim.
     * @return close 1 if voting should be closed,0 in case voting should not be closed,
     * -1 if voting has already been closed.
     */
    function _checkVoteClosingFinal(uint claimId, uint status) internal view returns(int8 close) {
        close = 0;
        uint coverId;
        (, coverId) = cd.getClaimCoverId(claimId);
        bytes4 curr = qd.getCurrencyOfCover(coverId);
        uint tokenx1e18 = m1.calculateTokenPrice(curr);
        uint accept;
        uint deny;
        (, accept, deny) = cd.getClaimsTokenCA(claimId);
        uint caTokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18);
        (, accept, deny) = cd.getClaimsTokenMV(claimId);
        uint mvTokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18);
        uint sumassured = qd.getCoverSumAssured(coverId).mul(DECIMAL1E18);
        if (status == 0 && caTokens >= sumassured.mul(10)) {
            close = 1;
        } else if (status >= 1 && status <= 5 && mvTokens >= sumassured.mul(10)) {
            close = 1;
        }
    }

    /**
     * @dev Changes the status of an existing claim id, based on current 
     * status and current conditions of the system
     * @param claimId Claim Id.
     * @param stat status number.  
     */
    function _setClaimStatus(uint claimId, uint stat) internal {

        uint origstat;
        uint state12Count;
        uint dateUpd;
        uint coverId;
        (, coverId, , origstat, dateUpd, state12Count) = cd.getClaim(claimId);
        (, origstat) = cd.getClaimStatusNumber(claimId);

        if (stat == 12 && origstat == 12) {
            cd.updateState12Count(claimId, 1);
        }
        cd.setClaimStatus(claimId, stat);

        if (state12Count >= 60 && stat == 12) {
            cd.setClaimStatus(claimId, 13);
            qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.ClaimDenied));
        }
        uint time = now;
        cd.setClaimdateUpd(claimId, time);

        if (stat >= 2 && stat <= 5) {
            p1.closeClaimsOraclise(claimId, cd.maxVotingTime());
        }

        if (stat == 12 && (dateUpd.add(cd.payoutRetryTime()) <= now) && (state12Count < 60)) {
            p1.closeClaimsOraclise(claimId, cd.payoutRetryTime());
        } else if (stat == 12 && (dateUpd.add(cd.payoutRetryTime()) > now) && (state12Count < 60)) {
            uint64 timeLeft = uint64((dateUpd.add(cd.payoutRetryTime())).sub(now));
            p1.closeClaimsOraclise(claimId, timeLeft);
        }
    }

    /**
     * @dev Submits a claim for a given cover note.
     * Set deposits flag against cover.
     */
    function _addClaim(uint coverId, uint time, address add) internal {
        tf.depositCN(coverId);
        uint len = cd.actualClaimLength();
        cd.addClaim(len, coverId, add, now);
        cd.callClaimEvent(coverId, add, len, time);
        qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.ClaimSubmitted));
        bytes4 curr = qd.getCurrencyOfCover(coverId);
        uint sumAssured = qd.getCoverSumAssured(coverId).mul(DECIMAL1E18);
        pd.changeCurrencyAssetVarMin(curr, pd.getCurrencyAssetVarMin(curr).add(sumAssured));
        p2.internalLiquiditySwap(curr);
        p1.closeClaimsOraclise(len, cd.maxVotingTime());
    }
}

// File: nexusmutual-contracts/contracts/ClaimsReward.sol

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

//Claims Reward Contract contains the functions for calculating number of tokens
// that will get rewarded, unlocked or burned depending upon the status of claim.

pragma solidity 0.5.7;







contract ClaimsReward is Iupgradable {
     using SafeMath for uint;

    NXMToken internal tk;
    TokenController internal tc;
    TokenFunctions internal tf;
    TokenData internal td;
    QuotationData internal qd;
    Claims internal c1;
    ClaimsData internal cd;
    Pool1 internal p1;
    Pool2 internal p2;
    PoolData internal pd;
    Governance internal gv;
    IPooledStaking internal pooledStaking;

    uint private constant DECIMAL1E18 = uint(10) ** 18;

    function changeDependentContractAddress() public onlyInternal {
        c1 = Claims(ms.getLatestAddress("CL"));
        cd = ClaimsData(ms.getLatestAddress("CD"));
        tk = NXMToken(ms.tokenAddress());
        tc = TokenController(ms.getLatestAddress("TC"));
        td = TokenData(ms.getLatestAddress("TD"));
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        p1 = Pool1(ms.getLatestAddress("P1"));
        p2 = Pool2(ms.getLatestAddress("P2"));
        pd = PoolData(ms.getLatestAddress("PD"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        gv = Governance(ms.getLatestAddress("GV"));
        pooledStaking = IPooledStaking(ms.getLatestAddress("PS"));
    }

    /// @dev Decides the next course of action for a given claim.
    function changeClaimStatus(uint claimid) public checkPause onlyInternal {

        uint coverid;
        (, coverid) = cd.getClaimCoverId(claimid);

        uint status;
        (, status) = cd.getClaimStatusNumber(claimid);

        // when current status is "Pending-Claim Assessor Vote"
        if (status == 0) {
            _changeClaimStatusCA(claimid, coverid, status);
        } else if (status >= 1 && status <= 5) {
            _changeClaimStatusMV(claimid, coverid, status);
        } else if (status == 12) { // when current status is "Claim Accepted Payout Pending"

            uint sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
            address payable coverHolder = qd.getCoverMemberAddress(coverid);
            bytes4 coverCurrency = qd.getCurrencyOfCover(coverid);
            bool success = p1.sendClaimPayout(coverid, claimid, sumAssured, coverHolder, coverCurrency);

            if (success) {
                tf.burnStakedTokens(coverid, coverCurrency, sumAssured);
                c1.setClaimStatus(claimid, 14);
            }
        }

        c1.changePendingClaimStart();
    }

    /// @dev Amount of tokens to be rewarded to a user for a particular vote id.
    /// @param check 1 -> CA vote, else member vote
    /// @param voteid vote id for which reward has to be Calculated
    /// @param flag if 1 calculate even if claimed,else don't calculate if already claimed
    /// @return tokenCalculated reward to be given for vote id
    /// @return lastClaimedCheck true if final verdict is still pending for that voteid
    /// @return tokens number of tokens locked under that voteid
    /// @return perc percentage of reward to be given.
    function getRewardToBeGiven(
        uint check,
        uint voteid,
        uint flag
    )
        public
        view
        returns (
            uint tokenCalculated,
            bool lastClaimedCheck,
            uint tokens,
            uint perc
        )

    {
        uint claimId;
        int8 verdict;
        bool claimed;
        uint tokensToBeDist;
        uint totalTokens;
        (tokens, claimId, verdict, claimed) = cd.getVoteDetails(voteid);
        lastClaimedCheck = false;
        int8 claimVerdict = cd.getFinalVerdict(claimId);
        if (claimVerdict == 0) {
            lastClaimedCheck = true;
        }

        if (claimVerdict == verdict && (claimed == false || flag == 1)) {

            if (check == 1) {
                (perc, , tokensToBeDist) = cd.getClaimRewardDetail(claimId);
            } else {
                (, perc, tokensToBeDist) = cd.getClaimRewardDetail(claimId);
            }

            if (perc > 0) {
                if (check == 1) {
                    if (verdict == 1) {
                        (, totalTokens, ) = cd.getClaimsTokenCA(claimId);
                    } else {
                        (, , totalTokens) = cd.getClaimsTokenCA(claimId);
                    }
                } else {
                    if (verdict == 1) {
                        (, totalTokens, ) = cd.getClaimsTokenMV(claimId);
                    }else {
                        (, , totalTokens) = cd.getClaimsTokenMV(claimId);
                    }
                }
                tokenCalculated = (perc.mul(tokens).mul(tokensToBeDist)).div(totalTokens.mul(100));


            }
        }
    }

    /// @dev Transfers all tokens held by contract to a new contract in case of upgrade.
    function upgrade(address _newAdd) public onlyInternal {
        uint amount = tk.balanceOf(address(this));
        if (amount > 0) {
            require(tk.transfer(_newAdd, amount));
        }

    }

    /// @dev Total reward in token due for claim by a user.
    /// @return total total number of tokens
    function getRewardToBeDistributedByUser(address _add) public view returns(uint total) {
        uint lengthVote = cd.getVoteAddressCALength(_add);
        uint lastIndexCA;
        uint lastIndexMV;
        uint tokenForVoteId;
        uint voteId;
        (lastIndexCA, lastIndexMV) = cd.getRewardDistributedIndex(_add);

        for (uint i = lastIndexCA; i < lengthVote; i++) {
            voteId = cd.getVoteAddressCA(_add, i);
            (tokenForVoteId, , , ) = getRewardToBeGiven(1, voteId, 0);
            total = total.add(tokenForVoteId);
        }

        lengthVote = cd.getVoteAddressMemberLength(_add);

        for (uint j = lastIndexMV; j < lengthVote; j++) {
            voteId = cd.getVoteAddressMember(_add, j);
            (tokenForVoteId, , , ) = getRewardToBeGiven(0, voteId, 0);
            total = total.add(tokenForVoteId);
        }
        return (total);
    }

    /// @dev Gets reward amount and claiming status for a given claim id.
    /// @return reward amount of tokens to user.
    /// @return claimed true if already claimed false if yet to be claimed.
    function getRewardAndClaimedStatus(uint check, uint claimId) public view returns(uint reward, bool claimed) {
        uint voteId;
        uint claimid;
        uint lengthVote;

        if (check == 1) {
            lengthVote = cd.getVoteAddressCALength(msg.sender);
            for (uint i = 0; i < lengthVote; i++) {
                voteId = cd.getVoteAddressCA(msg.sender, i);
                (, claimid, , claimed) = cd.getVoteDetails(voteId);
                if (claimid == claimId) { break; }
            }
        } else {
            lengthVote = cd.getVoteAddressMemberLength(msg.sender);
            for (uint j = 0; j < lengthVote; j++) {
                voteId = cd.getVoteAddressMember(msg.sender, j);
                (, claimid, , claimed) = cd.getVoteDetails(voteId);
                if (claimid == claimId) { break; }
            }
        }
        (reward, , , ) = getRewardToBeGiven(check, voteId, 1);

    }

    /**
     * @dev Function used to claim all pending rewards : Claims Assessment + Risk Assessment + Governance
     * Claim assesment, Risk assesment, Governance rewards
     */
    function claimAllPendingReward(uint records) public isMemberAndcheckPause {
        _claimRewardToBeDistributed(records);
        pooledStaking.withdrawReward(msg.sender);
        uint governanceRewards = gv.claimReward(msg.sender, records);
        if (governanceRewards > 0) {
            require(tk.transfer(msg.sender, governanceRewards));
        }
    }

    /**
     * @dev Function used to get pending rewards of a particular user address.
     * @param _add user address.
     * @return total reward amount of the user
     */
    function getAllPendingRewardOfUser(address _add) public view returns(uint) {
        uint caReward = getRewardToBeDistributedByUser(_add);
        uint pooledStakingReward = pooledStaking.stakerReward(_add);
        uint governanceReward = gv.getPendingReward(_add);
        return caReward.add(pooledStakingReward).add(governanceReward);
    }

    /// @dev Rewards/Punishes users who  participated in Claims assessment.
    //    Unlocking and burning of the tokens will also depend upon the status of claim.
    /// @param claimid Claim Id.
    function _rewardAgainstClaim(uint claimid, uint coverid, uint sumAssured, uint status) internal {
        uint premiumNXM = qd.getCoverPremiumNXM(coverid);
        bytes4 curr = qd.getCurrencyOfCover(coverid);
        uint distributableTokens = premiumNXM.mul(cd.claimRewardPerc()).div(100);//  20% of premium

        uint percCA;
        uint percMV;

        (percCA, percMV) = cd.getRewardStatus(status);
        cd.setClaimRewardDetail(claimid, percCA, percMV, distributableTokens);
        if (percCA > 0 || percMV > 0) {
            tc.mint(address(this), distributableTokens);
        }

        if (status == 6 || status == 9 || status == 11) {
            cd.changeFinalVerdict(claimid, -1);
            td.setDepositCN(coverid, false); // Unset flag
            tf.burnDepositCN(coverid); // burn Deposited CN

            pd.changeCurrencyAssetVarMin(curr, pd.getCurrencyAssetVarMin(curr).sub(sumAssured));
            p2.internalLiquiditySwap(curr);

        } else if (status == 7 || status == 8 || status == 10) {
            cd.changeFinalVerdict(claimid, 1);
            td.setDepositCN(coverid, false); // Unset flag
            tf.unlockCN(coverid);
            bool success = p1.sendClaimPayout(coverid, claimid, sumAssured, qd.getCoverMemberAddress(coverid), curr);
            if (success) {
                tf.burnStakedTokens(coverid, curr, sumAssured);
            }
        }
    }

    /// @dev Computes the result of Claim Assessors Voting for a given claim id.
    function _changeClaimStatusCA(uint claimid, uint coverid, uint status) internal {
        // Check if voting should be closed or not
        if (c1.checkVoteClosing(claimid) == 1) {
            uint caTokens = c1.getCATokens(claimid, 0); // converted in cover currency.
            uint accept;
            uint deny;
            uint acceptAndDeny;
            bool rewardOrPunish;
            uint sumAssured;
            (, accept) = cd.getClaimVote(claimid, 1);
            (, deny) = cd.getClaimVote(claimid, -1);
            acceptAndDeny = accept.add(deny);
            accept = accept.mul(100);
            deny = deny.mul(100);

            if (caTokens == 0) {
                status = 3;
            } else {
                sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
                // Min threshold reached tokens used for voting > 5* sum assured
                if (caTokens > sumAssured.mul(5)) {

                    if (accept.div(acceptAndDeny) > 70) {
                        status = 7;
                        qd.changeCoverStatusNo(coverid, uint8(QuotationData.CoverStatus.ClaimAccepted));
                        rewardOrPunish = true;
                    } else if (deny.div(acceptAndDeny) > 70) {
                        status = 6;
                        qd.changeCoverStatusNo(coverid, uint8(QuotationData.CoverStatus.ClaimDenied));
                        rewardOrPunish = true;
                    } else if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
                        status = 4;
                    } else {
                        status = 5;
                    }

                } else {

                    if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
                        status = 2;
                    } else {
                        status = 3;
                    }
                }
            }

            c1.setClaimStatus(claimid, status);

            if (rewardOrPunish) {
                _rewardAgainstClaim(claimid, coverid, sumAssured, status);
            }
        }
    }

    /// @dev Computes the result of Member Voting for a given claim id.
    function _changeClaimStatusMV(uint claimid, uint coverid, uint status) internal {

        // Check if voting should be closed or not
        if (c1.checkVoteClosing(claimid) == 1) {
            uint8 coverStatus;
            uint statusOrig = status;
            uint mvTokens = c1.getCATokens(claimid, 1); // converted in cover currency.

            // If tokens used for acceptance >50%, claim is accepted
            uint sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
            uint thresholdUnreached = 0;
            // Minimum threshold for member voting is reached only when
            // value of tokens used for voting > 5* sum assured of claim id
            if (mvTokens < sumAssured.mul(5)) {
                thresholdUnreached = 1;
            }

            uint accept;
            (, accept) = cd.getClaimMVote(claimid, 1);
            uint deny;
            (, deny) = cd.getClaimMVote(claimid, -1);

            if (accept.add(deny) > 0) {
                if (accept.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
                    statusOrig <= 5 && thresholdUnreached == 0) {
                    status = 8;
                    coverStatus = uint8(QuotationData.CoverStatus.ClaimAccepted);
                } else if (deny.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
                    statusOrig <= 5 && thresholdUnreached == 0) {
                    status = 9;
                    coverStatus = uint8(QuotationData.CoverStatus.ClaimDenied);
                }
            }

            if (thresholdUnreached == 1 && (statusOrig == 2 || statusOrig == 4)) {
                status = 10;
                coverStatus = uint8(QuotationData.CoverStatus.ClaimAccepted);
            } else if (thresholdUnreached == 1 && (statusOrig == 5 || statusOrig == 3 || statusOrig == 1)) {
                status = 11;
                coverStatus = uint8(QuotationData.CoverStatus.ClaimDenied);
            }

            c1.setClaimStatus(claimid, status);
            qd.changeCoverStatusNo(coverid, uint8(coverStatus));
            // Reward/Punish Claim Assessors and Members who participated in Claims assessment
            _rewardAgainstClaim(claimid, coverid, sumAssured, status);
        }
    }

    /// @dev Allows a user to claim all pending  Claims assessment rewards.
    function _claimRewardToBeDistributed(uint _records) internal {
        uint lengthVote = cd.getVoteAddressCALength(msg.sender);
        uint voteid;
        uint lastIndex;
        (lastIndex, ) = cd.getRewardDistributedIndex(msg.sender);
        uint total = 0;
        uint tokenForVoteId = 0;
        bool lastClaimedCheck;
        uint _days = td.lockCADays();
        bool claimed;
        uint counter = 0;
        uint claimId;
        uint perc;
        uint i;
        uint lastClaimed = lengthVote;

        for (i = lastIndex; i < lengthVote && counter < _records; i++) {
            voteid = cd.getVoteAddressCA(msg.sender, i);
            (tokenForVoteId, lastClaimedCheck, , perc) = getRewardToBeGiven(1, voteid, 0);
            if (lastClaimed == lengthVote && lastClaimedCheck == true) {
                lastClaimed = i;
            }
            (, claimId, , claimed) = cd.getVoteDetails(voteid);

            if (perc > 0 && !claimed) {
                counter++;
                cd.setRewardClaimed(voteid, true);
            } else if (perc == 0 && cd.getFinalVerdict(claimId) != 0 && !claimed) {
                (perc, , ) = cd.getClaimRewardDetail(claimId);
                if (perc == 0) {
                    counter++;
                }
                cd.setRewardClaimed(voteid, true);
            }
            if (tokenForVoteId > 0) {
                total = tokenForVoteId.add(total);
            }
        }
        if (lastClaimed == lengthVote) {
            cd.setRewardDistributedIndexCA(msg.sender, i);
        }
        else {
            cd.setRewardDistributedIndexCA(msg.sender, lastClaimed);
        }
        lengthVote = cd.getVoteAddressMemberLength(msg.sender);
        lastClaimed = lengthVote;
        _days = _days.mul(counter);
        if (tc.tokensLockedAtTime(msg.sender, "CLA", now) > 0) {
            tc.reduceLock(msg.sender, "CLA", _days);
        }
        (, lastIndex) = cd.getRewardDistributedIndex(msg.sender);
        lastClaimed = lengthVote;
        counter = 0;
        for (i = lastIndex; i < lengthVote && counter < _records; i++) {
            voteid = cd.getVoteAddressMember(msg.sender, i);
            (tokenForVoteId, lastClaimedCheck, , ) = getRewardToBeGiven(0, voteid, 0);
            if (lastClaimed == lengthVote && lastClaimedCheck == true) {
                lastClaimed = i;
            }
            (, claimId, , claimed) = cd.getVoteDetails(voteid);
            if (claimed == false && cd.getFinalVerdict(claimId) != 0) {
                cd.setRewardClaimed(voteid, true);
                counter++;
            }
            if (tokenForVoteId > 0) {
                total = tokenForVoteId.add(total);
            }
        }
        if (total > 0) {
            require(tk.transfer(msg.sender, total));
        }
        if (lastClaimed == lengthVote) {
            cd.setRewardDistributedIndexMV(msg.sender, i);
        }
        else {
            cd.setRewardDistributedIndexMV(msg.sender, lastClaimed);
        }
    }

    /**
     * @dev Function used to claim the commission earned by the staker.
     */
    function _claimStakeCommission(uint _records, address _user) external onlyInternal {
        uint total=0;
        uint len = td.getStakerStakedContractLength(_user);
        uint lastCompletedStakeCommission = td.lastCompletedStakeCommission(_user);
        uint commissionEarned;
        uint commissionRedeemed;
        uint maxCommission;
        uint lastCommisionRedeemed = len;
        uint counter;
        uint i;

        for (i = lastCompletedStakeCommission; i < len && counter < _records; i++) {
            commissionRedeemed = td.getStakerRedeemedStakeCommission(_user, i);
            commissionEarned = td.getStakerEarnedStakeCommission(_user, i);
            maxCommission = td.getStakerInitialStakedAmountOnContract(
                _user, i).mul(td.stakerMaxCommissionPer()).div(100);
            if (lastCommisionRedeemed == len && maxCommission != commissionEarned)
                lastCommisionRedeemed = i;
            td.pushRedeemedStakeCommissions(_user, i, commissionEarned.sub(commissionRedeemed));
            total = total.add(commissionEarned.sub(commissionRedeemed));
            counter++;
        }
        if (lastCommisionRedeemed == len) {
            td.setLastCompletedStakeCommissionIndex(_user, i);
        } else {
            td.setLastCompletedStakeCommissionIndex(_user, lastCommisionRedeemed);
        }

        if (total > 0)
            require(tk.transfer(_user, total)); //solhint-disable-line
    }
}

// File: nexusmutual-contracts/contracts/MemberRoles.sol

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;










contract MemberRoles is IMemberRoles, Governed, Iupgradable {

    TokenController public dAppToken;
    TokenData internal td;
    QuotationData internal qd;
    ClaimsReward internal cr;
    Governance internal gv;
    TokenFunctions internal tf;
    NXMToken public tk;

    struct MemberRoleDetails {
        uint memberCounter;
        mapping(address => bool) memberActive;
        address[] memberAddress;
        address authorized;
    }

    enum Role {UnAssigned, AdvisoryBoard, Member, Owner}

    event switchedMembership(address indexed previousMember, address indexed newMember, uint timeStamp);

    MemberRoleDetails[] internal memberRoleData;
    bool internal constructorCheck;
    uint public maxABCount;
    bool public launched;
    uint public launchedOn;
    modifier checkRoleAuthority(uint _memberRoleId) {
        if (memberRoleData[_memberRoleId].authorized != address(0))
            require(msg.sender == memberRoleData[_memberRoleId].authorized);
        else
            require(isAuthorizedToGovern(msg.sender), "Not Authorized");
        _;
    }

    /**
     * @dev to swap advisory board member
     * @param _newABAddress is address of new AB member
     * @param _removeAB is advisory board member to be removed
     */
    function swapABMember (
        address _newABAddress,
        address _removeAB
    )
    external
    checkRoleAuthority(uint(Role.AdvisoryBoard)) {

        _updateRole(_newABAddress, uint(Role.AdvisoryBoard), true);
        _updateRole(_removeAB, uint(Role.AdvisoryBoard), false);

    }

    /**
     * @dev to swap the owner address
     * @param _newOwnerAddress is the new owner address
     */
    function swapOwner (
        address _newOwnerAddress
    )
    external {
        require(msg.sender == address(ms));
        _updateRole(ms.owner(), uint(Role.Owner), false);
        _updateRole(_newOwnerAddress, uint(Role.Owner), true);
    }

    /**
     * @dev is used to add initital advisory board members
     * @param abArray is the list of initial advisory board members
     */
    function addInitialABMembers(address[] calldata abArray) external onlyOwner {

        //Ensure that NXMaster has initialized.
        require(ms.masterInitialized());

        require(maxABCount >= 
            SafeMath.add(numberOfMembers(uint(Role.AdvisoryBoard)), abArray.length)
        );
        //AB count can't exceed maxABCount
        for (uint i = 0; i < abArray.length; i++) {
            require(checkRole(abArray[i], uint(MemberRoles.Role.Member)));
            _updateRole(abArray[i], uint(Role.AdvisoryBoard), true);   
        }
    }

    /**
     * @dev to change max number of AB members allowed
     * @param _val is the new value to be set
     */
    function changeMaxABCount(uint _val) external onlyInternal {
        maxABCount = _val;
    }

    /**
     * @dev Iupgradable Interface to update dependent contract address
     */
    function changeDependentContractAddress() public {
        td = TokenData(ms.getLatestAddress("TD"));
        cr = ClaimsReward(ms.getLatestAddress("CR"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        gv = Governance(ms.getLatestAddress("GV"));
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tk = NXMToken(ms.tokenAddress());
        dAppToken = TokenController(ms.getLatestAddress("TC"));
    }

    /**
     * @dev to change the master address
     * @param _masterAddress is the new master address
     */
    function changeMasterAddress(address _masterAddress) public {
        if (masterAddress != address(0))
            require(masterAddress == msg.sender);
        masterAddress = _masterAddress;
        ms = INXMMaster(_masterAddress);
        nxMasterAddress = _masterAddress;
        
    }
    
    /**
     * @dev to initiate the member roles
     * @param _firstAB is the address of the first AB member
     * @param memberAuthority is the authority (role) of the member
     */
    function memberRolesInitiate (address _firstAB, address memberAuthority) public {
        require(!constructorCheck);
        _addInitialMemberRoles(_firstAB, memberAuthority);
        constructorCheck = true;
    }

    /// @dev Adds new member role
    /// @param _roleName New role name
    /// @param _roleDescription New description hash
    /// @param _authorized Authorized member against every role id
    function addRole( //solhint-disable-line
        bytes32 _roleName,
        string memory _roleDescription,
        address _authorized
    )
    public
    onlyAuthorizedToGovern {
        _addRole(_roleName, _roleDescription, _authorized);
    }

    /// @dev Assign or Delete a member from specific role.
    /// @param _memberAddress Address of Member
    /// @param _roleId RoleId to update
    /// @param _active active is set to be True if we want to assign this role to member, False otherwise!
    function updateRole( //solhint-disable-line
        address _memberAddress,
        uint _roleId,
        bool _active
    )
    public
    checkRoleAuthority(_roleId) {
        _updateRole(_memberAddress, _roleId, _active);
    }

    /**
     * @dev to add members before launch
     * @param userArray is list of addresses of members
     * @param tokens is list of tokens minted for each array element
     */
    function addMembersBeforeLaunch(address[] memory userArray, uint[] memory tokens) public onlyOwner {
        require(!launched);

        for (uint i=0; i < userArray.length; i++) {
            require(!ms.isMember(userArray[i]));
            dAppToken.addToWhitelist(userArray[i]);
            _updateRole(userArray[i], uint(Role.Member), true);
            dAppToken.mint(userArray[i], tokens[i]);
        }
        launched = true;
        launchedOn = now;

    }

   /** 
     * @dev Called by user to pay joining membership fee
     */ 
    function payJoiningFee(address _userAddress) public payable {
        require(_userAddress != address(0));
        require(!ms.isPause(), "Emergency Pause Applied");
        if (msg.sender == address(ms.getLatestAddress("QT"))) {
            require(td.walletAddress() != address(0), "No walletAddress present");
            dAppToken.addToWhitelist(_userAddress);
            _updateRole(_userAddress, uint(Role.Member), true);            
            td.walletAddress().transfer(msg.value); 
        } else {
            require(!qd.refundEligible(_userAddress));
            require(!ms.isMember(_userAddress));
            require(msg.value == td.joiningFee());
            qd.setRefundEligible(_userAddress, true);
        }
    }

    /**
     * @dev to perform kyc verdict
     * @param _userAddress whose kyc is being performed
     * @param verdict of kyc process
     */
    function kycVerdict(address payable _userAddress, bool verdict) public {

        require(msg.sender == qd.kycAuthAddress());
        require(!ms.isPause());
        require(_userAddress != address(0));
        require(!ms.isMember(_userAddress));
        require(qd.refundEligible(_userAddress));
        if (verdict) {
            qd.setRefundEligible(_userAddress, false);
            uint fee = td.joiningFee();
            dAppToken.addToWhitelist(_userAddress);
            _updateRole(_userAddress, uint(Role.Member), true);
            td.walletAddress().transfer(fee); //solhint-disable-line
            
        } else {
            qd.setRefundEligible(_userAddress, false);
            _userAddress.transfer(td.joiningFee()); //solhint-disable-line
        }
    }

    /**
     * @dev Called by existed member if wish to Withdraw membership.
     */
    function withdrawMembership() public {
        require(!ms.isPause() && ms.isMember(msg.sender));
        require(dAppToken.totalLockedBalance(msg.sender, now) == 0); //solhint-disable-line
        require(!tf.isLockedForMemberVote(msg.sender)); // No locked tokens for Member/Governance voting
        require(cr.getAllPendingRewardOfUser(msg.sender) == 0); // No pending reward to be claimed(claim assesment).
        require(dAppToken.tokensUnlockable(msg.sender, "CLA") == 0, "Member should have no CLA unlockable tokens");
        gv.removeDelegation(msg.sender);
        dAppToken.burnFrom(msg.sender, tk.balanceOf(msg.sender));
        _updateRole(msg.sender, uint(Role.Member), false);
        dAppToken.removeFromWhitelist(msg.sender); // need clarification on whitelist        
    }


    /**
     * @dev Called by existed member if wish to switch membership to other address.
     * @param _add address of user to forward membership.
     */
    function switchMembership(address _add) external {
        require(!ms.isPause() && ms.isMember(msg.sender) && !ms.isMember(_add));
        require(dAppToken.totalLockedBalance(msg.sender, now) == 0); //solhint-disable-line
        require(!tf.isLockedForMemberVote(msg.sender)); // No locked tokens for Member/Governance voting
        require(cr.getAllPendingRewardOfUser(msg.sender) == 0); // No pending reward to be claimed(claim assesment).
        require(dAppToken.tokensUnlockable(msg.sender, "CLA") == 0, "Member should have no CLA unlockable tokens");
        gv.removeDelegation(msg.sender);
        dAppToken.addToWhitelist(_add);
        _updateRole(_add, uint(Role.Member), true);
        tk.transferFrom(msg.sender, _add, tk.balanceOf(msg.sender));
        _updateRole(msg.sender, uint(Role.Member), false);
        dAppToken.removeFromWhitelist(msg.sender);
        emit switchedMembership(msg.sender, _add, now);
    }

    /// @dev Return number of member roles
    function totalRoles() public view returns(uint256) { //solhint-disable-line
        return memberRoleData.length;
    }

    /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
    /// @param _roleId roleId to update its Authorized Address
    /// @param _newAuthorized New authorized address against role id
    function changeAuthorized(uint _roleId, address _newAuthorized) public checkRoleAuthority(_roleId) { //solhint-disable-line
        memberRoleData[_roleId].authorized = _newAuthorized;
    }

    /// @dev Gets the member addresses assigned by a specific role
    /// @param _memberRoleId Member role id
    /// @return roleId Role id
    /// @return allMemberAddress Member addresses of specified role id
    function members(uint _memberRoleId) public view returns(uint, address[] memory memberArray) { //solhint-disable-line
        uint length = memberRoleData[_memberRoleId].memberAddress.length;
        uint i;
        uint j = 0;
        memberArray = new address[](memberRoleData[_memberRoleId].memberCounter);
        for (i = 0; i < length; i++) {
            address member = memberRoleData[_memberRoleId].memberAddress[i];
            if (memberRoleData[_memberRoleId].memberActive[member] && !_checkMemberInArray(member, memberArray)) { //solhint-disable-line
                memberArray[j] = member;
                j++;
            }
        }

        return (_memberRoleId, memberArray);
    }

    /// @dev Gets all members' length
    /// @param _memberRoleId Member role id
    /// @return memberRoleData[_memberRoleId].memberCounter Member length
    function numberOfMembers(uint _memberRoleId) public view returns(uint) { //solhint-disable-line
        return memberRoleData[_memberRoleId].memberCounter;
    }

    /// @dev Return member address who holds the right to add/remove any member from specific role.
    function authorized(uint _memberRoleId) public view returns(address) { //solhint-disable-line
        return memberRoleData[_memberRoleId].authorized;
    }

    /// @dev Get All role ids array that has been assigned to a member so far.
    function roles(address _memberAddress) public view returns(uint[] memory) { //solhint-disable-line
        uint length = memberRoleData.length;
        uint[] memory assignedRoles = new uint[](length);
        uint counter = 0; 
        for (uint i = 1; i < length; i++) {
            if (memberRoleData[i].memberActive[_memberAddress]) {
                assignedRoles[counter] = i;
                counter++;
            }
        }
        return assignedRoles;
    }

    /// @dev Returns true if the given role id is assigned to a member.
    /// @param _memberAddress Address of member
    /// @param _roleId Checks member's authenticity with the roleId.
    /// i.e. Returns true if this roleId is assigned to member
    function checkRole(address _memberAddress, uint _roleId) public view returns(bool) { //solhint-disable-line
        if (_roleId == uint(Role.UnAssigned))
            return true;
        else
            if (memberRoleData[_roleId].memberActive[_memberAddress]) //solhint-disable-line
                return true;
            else
                return false;
    }

    /// @dev Return total number of members assigned against each role id.
    /// @return totalMembers Total members in particular role id
    function getMemberLengthForAllRoles() public view returns(uint[] memory totalMembers) { //solhint-disable-line
        totalMembers = new uint[](memberRoleData.length);
        for (uint i = 0; i < memberRoleData.length; i++) {
            totalMembers[i] = numberOfMembers(i);
        }
    }

    /**
     * @dev to update the member roles
     * @param _memberAddress in concern
     * @param _roleId the id of role
     * @param _active if active is true, add the member, else remove it 
     */
    function _updateRole(address _memberAddress,
        uint _roleId,
        bool _active) internal {
        // require(_roleId != uint(Role.TokenHolder), "Membership to Token holder is detected automatically");
        if (_active) {
            require(!memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = SafeMath.add(memberRoleData[_roleId].memberCounter, 1);
            memberRoleData[_roleId].memberActive[_memberAddress] = true;
            memberRoleData[_roleId].memberAddress.push(_memberAddress);
        } else {
            require(memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = SafeMath.sub(memberRoleData[_roleId].memberCounter, 1);
            delete memberRoleData[_roleId].memberActive[_memberAddress];
        }
    }

    /// @dev Adds new member role
    /// @param _roleName New role name
    /// @param _roleDescription New description hash
    /// @param _authorized Authorized member against every role id
    function _addRole(
        bytes32 _roleName,
        string memory _roleDescription,
        address _authorized
    ) internal {
        emit MemberRole(memberRoleData.length, _roleName, _roleDescription);
        memberRoleData.push(MemberRoleDetails(0, new address[](0), _authorized));
    }

    /**
     * @dev to check if member is in the given member array
     * @param _memberAddress in concern
     * @param memberArray in concern
     * @return boolean to represent the presence
     */
    function _checkMemberInArray(
        address _memberAddress,
        address[] memory memberArray
    )
        internal
        pure
        returns(bool memberExists)
    {
        uint i;
        for (i = 0; i < memberArray.length; i++) {
            if (memberArray[i] == _memberAddress) {
                memberExists = true;
                break;
            }
        }
    }

    /**
     * @dev to add initial member roles
     * @param _firstAB is the member address to be added
     * @param memberAuthority is the member authority(role) to be added for
     */
    function _addInitialMemberRoles(address _firstAB, address memberAuthority) internal {
        maxABCount = 5;
        _addRole("Unassigned", "Unassigned", address(0));
        _addRole(
            "Advisory Board",
            "Selected few members that are deeply entrusted by the dApp. An ideal advisory board should be a mix of skills of domain, governance, research, technology, consulting etc to improve the performance of the dApp.", //solhint-disable-line
            address(0)
        );
        _addRole(
            "Member",
            "Represents all users of Mutual.", //solhint-disable-line
            memberAuthority
        );
        _addRole(
            "Owner",
            "Represents Owner of Mutual.", //solhint-disable-line
            address(0)
        );
        // _updateRole(_firstAB, uint(Role.AdvisoryBoard), true);
        _updateRole(_firstAB, uint(Role.Owner), true);
        // _updateRole(_firstAB, uint(Role.Member), true);
        launchedOn = 0;
    }

    function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool) {
        address memberAddress = memberRoleData[_memberRoleId].memberAddress[index];
        return (memberAddress, memberRoleData[_memberRoleId].memberActive[memberAddress]);
    }

    function membersLength(uint _memberRoleId) external view returns (uint) {
        return memberRoleData[_memberRoleId].memberAddress.length;
    }
}

// File: nexusmutual-contracts/contracts/ProposalCategory.sol

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */
pragma solidity 0.5.7;






contract ProposalCategory is  Governed, IProposalCategory, Iupgradable {

    bool public constructorCheck;
    MemberRoles internal mr;

    struct CategoryStruct {
        uint memberRoleToVote;
        uint majorityVotePerc;
        uint quorumPerc;
        uint[] allowedToCreateProposal;
        uint closingTime;
        uint minStake;
    }

    struct CategoryAction {
        uint defaultIncentive;
        address contractAddress;
        bytes2 contractName;
    }
    
    CategoryStruct[] internal allCategory;
    mapping (uint => CategoryAction) internal categoryActionData;
    mapping (uint => uint) public categoryABReq;
    mapping (uint => uint) public isSpecialResolution;
    mapping (uint => bytes) public categoryActionHashes;

    bool public categoryActionHashUpdated;

    /**
    * @dev Restricts calls to deprecated functions
    */
    modifier deprecated() {
        revert("Function deprecated");
        _;
    }

    /**
    * @dev Adds new category (Discontinued, moved functionality to newCategory)
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    */
    function addCategory(
        string calldata _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] calldata _allowedToCreateProposal,
        uint _closingTime,
        string calldata _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] calldata _incentives
    ) 
        external
        deprecated 
    {
    }

    /**
    * @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    */
    function proposalCategoryInitiate() external deprecated { //solhint-disable-line
    }

    /**
    * @dev Initiates Default action function hashes for existing categories
    * To be called after the contract has been upgraded by governance
    */
    function updateCategoryActionHashes() external onlyOwner {

        require(!categoryActionHashUpdated, "Category action hashes already updated");
        categoryActionHashUpdated = true;
        categoryActionHashes[1] = abi.encodeWithSignature("addRole(bytes32,string,address)");
        categoryActionHashes[2] = abi.encodeWithSignature("updateRole(address,uint256,bool)");
        categoryActionHashes[3] = abi.encodeWithSignature("newCategory(string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)");//solhint-disable-line
        categoryActionHashes[4] = abi.encodeWithSignature("editCategory(uint256,string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)");//solhint-disable-line
        categoryActionHashes[5] = abi.encodeWithSignature("upgradeContractImplementation(bytes2,address)");
        categoryActionHashes[6] = abi.encodeWithSignature("startEmergencyPause()");
        categoryActionHashes[7] = abi.encodeWithSignature("addEmergencyPause(bool,bytes4)");
        categoryActionHashes[8] = abi.encodeWithSignature("burnCAToken(uint256,uint256,address)");
        categoryActionHashes[9] = abi.encodeWithSignature("setUserClaimVotePausedOn(address)");
        categoryActionHashes[12] = abi.encodeWithSignature("transferEther(uint256,address)");
        categoryActionHashes[13] = abi.encodeWithSignature("addInvestmentAssetCurrency(bytes4,address,bool,uint64,uint64,uint8)");//solhint-disable-line
        categoryActionHashes[14] = abi.encodeWithSignature("changeInvestmentAssetHoldingPerc(bytes4,uint64,uint64)");
        categoryActionHashes[15] = abi.encodeWithSignature("changeInvestmentAssetStatus(bytes4,bool)");
        categoryActionHashes[16] = abi.encodeWithSignature("swapABMember(address,address)");
        categoryActionHashes[17] = abi.encodeWithSignature("addCurrencyAssetCurrency(bytes4,address,uint256)");
        categoryActionHashes[20] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[21] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[22] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[23] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[24] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[25] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[26] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[27] = abi.encodeWithSignature("updateAddressParameters(bytes8,address)");
        categoryActionHashes[28] = abi.encodeWithSignature("updateOwnerParameters(bytes8,address)");
        categoryActionHashes[29] = abi.encodeWithSignature("upgradeContract(bytes2,address)");
        categoryActionHashes[30] = abi.encodeWithSignature("changeCurrencyAssetAddress(bytes4,address)");
        categoryActionHashes[31] = abi.encodeWithSignature("changeCurrencyAssetBaseMin(bytes4,uint256)");
        categoryActionHashes[32] = abi.encodeWithSignature("changeInvestmentAssetAddressAndDecimal(bytes4,address,uint8)");//solhint-disable-line
        categoryActionHashes[33] = abi.encodeWithSignature("externalLiquidityTrade()");
    }

    /**
    * @dev Gets Total number of categories added till now
    */
    function totalCategories() external view returns(uint) {
        return allCategory.length;
    }

    /**
    * @dev Gets category details
    */
    function category(uint _categoryId) external view returns(uint, uint, uint, uint, uint[] memory, uint, uint) {
        return(
            _categoryId,
            allCategory[_categoryId].memberRoleToVote,
            allCategory[_categoryId].majorityVotePerc,
            allCategory[_categoryId].quorumPerc,
            allCategory[_categoryId].allowedToCreateProposal,
            allCategory[_categoryId].closingTime,
            allCategory[_categoryId].minStake
        );
    }

    /**
    * @dev Gets category ab required and isSpecialResolution
    * @return the category id
    * @return if AB voting is required
    * @return is category a special resolution
    */
    function categoryExtendedData(uint _categoryId) external view returns(uint, uint, uint) {
        return(
            _categoryId,
            categoryABReq[_categoryId],
            isSpecialResolution[_categoryId]
        );
    }

    /**
     * @dev Gets the category acion details
     * @param _categoryId is the category id in concern
     * @return the category id
     * @return the contract address
     * @return the contract name
     * @return the default incentive
     */
    function categoryAction(uint _categoryId) external view returns(uint, address, bytes2, uint) {

        return(
            _categoryId,
            categoryActionData[_categoryId].contractAddress,
            categoryActionData[_categoryId].contractName,
            categoryActionData[_categoryId].defaultIncentive
        );
    }

    /**
     * @dev Gets the category acion details of a category id 
     * @param _categoryId is the category id in concern
     * @return the category id
     * @return the contract address
     * @return the contract name
     * @return the default incentive
     * @return action function hash
     */
    function categoryActionDetails(uint _categoryId) external view returns(uint, address, bytes2, uint, bytes memory) {
        return(
            _categoryId,
            categoryActionData[_categoryId].contractAddress,
            categoryActionData[_categoryId].contractName,
            categoryActionData[_categoryId].defaultIncentive,
            categoryActionHashes[_categoryId]
        );
    }

    /**
    * @dev Updates dependant contract addresses
    */
    function changeDependentContractAddress() public {
        mr = MemberRoles(ms.getLatestAddress("MR"));
    }

    /**
    * @dev Adds new category
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    * @param _functionHash function signature to be executed
    */
    function newCategory(
        string memory _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives,
        string memory _functionHash
    ) 
        public
        onlyAuthorizedToGovern 
    {

        require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

        require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);
        
        require(_incentives[3] <= 1, "Invalid special resolution flag");
        
        //If category is special resolution role authorized should be member
        if (_incentives[3] == 1) {
            require(_memberRoleToVote == uint(MemberRoles.Role.Member));
            _majorityVotePerc = 0;
            _quorumPerc = 0;
        }

        _addCategory(
            _name, 
            _memberRoleToVote,
            _majorityVotePerc, 
            _quorumPerc,
            _allowedToCreateProposal,
            _closingTime,
            _actionHash,
            _contractAddress,
            _contractName,
            _incentives
        );


        if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
            categoryActionHashes[allCategory.length - 1] = abi.encodeWithSignature(_functionHash);
        }
    }

    /**
     * @dev Changes the master address and update it's instance
     * @param _masterAddress is the new master address
     */
    function changeMasterAddress(address _masterAddress) public {
        if (masterAddress != address(0))
            require(masterAddress == msg.sender);
        masterAddress = _masterAddress;
        ms = INXMMaster(_masterAddress);
        nxMasterAddress = _masterAddress;
        
    }

    /**
    * @dev Updates category details (Discontinued, moved functionality to editCategory)
    * @param _categoryId Category id that needs to be updated
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    */
    function updateCategory(
        uint _categoryId, 
        string memory _name, 
        uint _memberRoleToVote, 
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives
    )
        public
        deprecated
    {
    }

    /**
    * @dev Updates category details
    * @param _categoryId Category id that needs to be updated
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    * @param _functionHash function signature to be executed
    */
    function editCategory(
        uint _categoryId, 
        string memory _name, 
        uint _memberRoleToVote, 
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives,
        string memory _functionHash
    )
        public
        onlyAuthorizedToGovern
    {
        require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");

        require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

        require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

        require(_incentives[3] <= 1, "Invalid special resolution flag");
        
        //If category is special resolution role authorized should be member
        if (_incentives[3] == 1) {
            require(_memberRoleToVote == uint(MemberRoles.Role.Member));
            _majorityVotePerc = 0;
            _quorumPerc = 0;
        }

        delete categoryActionHashes[_categoryId];
        if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
            categoryActionHashes[_categoryId] = abi.encodeWithSignature(_functionHash);
        }
        allCategory[_categoryId].memberRoleToVote = _memberRoleToVote;
        allCategory[_categoryId].majorityVotePerc = _majorityVotePerc;
        allCategory[_categoryId].closingTime = _closingTime;
        allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal;
        allCategory[_categoryId].minStake = _incentives[0];
        allCategory[_categoryId].quorumPerc = _quorumPerc;
        categoryActionData[_categoryId].defaultIncentive = _incentives[1];
        categoryActionData[_categoryId].contractName = _contractName;
        categoryActionData[_categoryId].contractAddress = _contractAddress;
        categoryABReq[_categoryId] = _incentives[2];
        isSpecialResolution[_categoryId] = _incentives[3];
        emit Category(_categoryId, _name, _actionHash);
    }

    /**
    * @dev Internal call to add new category
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    */
    function _addCategory(
        string memory _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives
    ) 
        internal
    {
        require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");
        allCategory.push(
            CategoryStruct(
                _memberRoleToVote,
                _majorityVotePerc,
                _quorumPerc,
                _allowedToCreateProposal,
                _closingTime,
                _incentives[0]
            )
        );
        uint categoryId = allCategory.length - 1;
        categoryActionData[categoryId] = CategoryAction(_incentives[1], _contractAddress, _contractName);
        categoryABReq[categoryId] = _incentives[2];
        isSpecialResolution[categoryId] = _incentives[3];
        emit Category(categoryId, _name, _actionHash);
    }

    /**
    * @dev Internal call to check if given roles are valid or not
    */
    function _verifyMemberRoles(uint _memberRoleToVote, uint[] memory _allowedToCreateProposal) 
    internal view returns(uint) { 
        uint totalRoles = mr.totalRoles();
        if (_memberRoleToVote >= totalRoles) {
            return 0;
        }
        for (uint i = 0; i < _allowedToCreateProposal.length; i++) {
            if (_allowedToCreateProposal[i] >= totalRoles) {
                return 0;
            }
        }
        return 1;
    }

}

// File: nexusmutual-contracts/contracts/external/govblocks-protocol/interfaces/IGovernance.sol

/* Copyright (C) 2017 GovBlocks.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract IGovernance { 

    event Proposal(
        address indexed proposalOwner,
        uint256 indexed proposalId,
        uint256 dateAdd,
        string proposalTitle,
        string proposalSD,
        string proposalDescHash
    );

    event Solution(
        uint256 indexed proposalId,
        address indexed solutionOwner,
        uint256 indexed solutionId,
        string solutionDescHash,
        uint256 dateAdd
    );

    event Vote(
        address indexed from,
        uint256 indexed proposalId,
        uint256 indexed voteId,
        uint256 dateAdd,
        uint256 solutionChosen
    );

    event RewardClaimed(
        address indexed member,
        uint gbtReward
    );

    /// @dev VoteCast event is called whenever a vote is cast that can potentially close the proposal. 
    event VoteCast (uint256 proposalId);

    /// @dev ProposalAccepted event is called when a proposal is accepted so that a server can listen that can 
    ///      call any offchain actions
    event ProposalAccepted (uint256 proposalId);

    /// @dev CloseProposalOnTime event is called whenever a proposal is created or updated to close it on time.
    event CloseProposalOnTime (
        uint256 indexed proposalId,
        uint256 time
    );

    /// @dev ActionSuccess event is called whenever an onchain action is executed.
    event ActionSuccess (
        uint256 proposalId
    );

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string calldata _proposalTitle,
        string calldata _proposalSD,
        string calldata _proposalDescHash,
        uint _categoryId
    ) 
        external;

    /// @dev Edits the details of an existing proposal and creates new version
    /// @param _proposalId Proposal id that details needs to be updated
    /// @param _proposalDescHash Proposal description hash having long and short description of proposal.
    function updateProposal(
        uint _proposalId, 
        string calldata _proposalTitle, 
        string calldata _proposalSD, 
        string calldata _proposalDescHash
    ) 
        external;

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    function categorizeProposal(
        uint _proposalId, 
        uint _categoryId,
        uint _incentives
    ) 
        external;

    /// @dev Initiates add solution 
    /// @param _solutionHash Solution hash having required data against adding solution
    function addSolution(
        uint _proposalId,
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external; 

    /// @dev Opens proposal for voting
    function openProposalForVoting(uint _proposalId) external;

    /// @dev Submit proposal with solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function submitProposalWithSolution(
        uint _proposalId, 
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external;

    /// @dev Creates a new proposal with solution and votes for the solution
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function createProposalwithSolution(
        string calldata _proposalTitle, 
        string calldata _proposalSD, 
        string calldata _proposalDescHash,
        uint _categoryId, 
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external;

    /// @dev Casts vote
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen while voting. _solutionChosen[0] is the chosen solution
    function submitVote(uint _proposalId, uint _solutionChosen) external;

    function closeProposal(uint _proposalId) external;

    function claimReward(address _memberAddress, uint _maxRecords) external returns(uint pendingDAppReward); 

    function proposal(uint _proposalId)
        external
        view
        returns(
            uint proposalId,
            uint category,
            uint status,
            uint finalVerdict,
            uint totalReward
        );

    function canCloseProposal(uint _proposalId) public view returns(uint closeValue);

    function pauseProposal(uint _proposalId) public;
    
    function resumeProposal(uint _proposalId) public;
    
    function allowedToCatgorize() public view returns(uint roleId);

}

// File: nexusmutual-contracts/contracts/Governance.sol

// /* Copyright (C) 2017 GovBlocks.io

//   This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.

//   This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.

//   You should have received a copy of the GNU General Public License
//     along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;





contract Governance is IGovernance, Iupgradable {

    using SafeMath for uint;

    enum ProposalStatus { 
        Draft,
        AwaitingSolution,
        VotingStarted,
        Accepted,
        Rejected,
        Majority_Not_Reached_But_Accepted,
        Denied
    }

    struct ProposalData {
        uint propStatus;
        uint finalVerdict;
        uint category;
        uint commonIncentive;
        uint dateUpd;
        address owner;
    }

    struct ProposalVote {
        address voter;
        uint proposalId;
        uint dateAdd;
    }

    struct VoteTally {
        mapping(uint=>uint) memberVoteValue;
        mapping(uint=>uint) abVoteValue;
        uint voters;
    }

    struct DelegateVote {
        address follower;
        address leader;
        uint lastUpd;
    }

    ProposalVote[] internal allVotes;
    DelegateVote[] public allDelegation;

    mapping(uint => ProposalData) internal allProposalData;
    mapping(uint => bytes[]) internal allProposalSolutions;
    mapping(address => uint[]) internal allVotesByMember;
    mapping(uint => mapping(address => bool)) public rewardClaimed;
    mapping (address => mapping(uint => uint)) public memberProposalVote;
    mapping (address => uint) public followerDelegation;
    mapping (address => uint) internal followerCount;
    mapping (address => uint[]) internal leaderDelegation;
    mapping (uint => VoteTally) public proposalVoteTally;
    mapping (address => bool) public isOpenForDelegation;
    mapping (address => uint) public lastRewardClaimed;

    bool internal constructorCheck;
    uint public tokenHoldingTime;
    uint internal roleIdAllowedToCatgorize;
    uint internal maxVoteWeigthPer;
    uint internal specialResolutionMajPerc;
    uint internal maxFollowers;
    uint internal totalProposals;
    uint internal maxDraftTime;

    MemberRoles internal memberRole;
    ProposalCategory internal proposalCategory;
    TokenController internal tokenInstance;

    mapping(uint => uint) public proposalActionStatus;
    mapping(uint => uint) internal proposalExecutionTime;
    mapping(uint => mapping(address => bool)) public proposalRejectedByAB;
    mapping(uint => uint) internal actionRejectedCount;

    bool internal actionParamsInitialised;
    uint internal actionWaitingTime;
    uint constant internal AB_MAJ_TO_REJECT_ACTION = 3;

    enum ActionStatus {
        Pending,
        Accepted,
        Rejected,
        Executed,
        NoAction
    }

    /**
    * @dev Called whenever an action execution is failed.
    */
    event ActionFailed (
        uint256 proposalId
    );

    /**
    * @dev Called whenever an AB member rejects the action execution.
    */
    event ActionRejected (
        uint256 indexed proposalId,
        address rejectedBy
    );

    /**
    * @dev Checks if msg.sender is proposal owner
    */
    modifier onlyProposalOwner(uint _proposalId) {
        require(msg.sender == allProposalData[_proposalId].owner, "Not allowed");
        _;
    }

    /**
    * @dev Checks if proposal is opened for voting
    */
    modifier voteNotStarted(uint _proposalId) {
        require(allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted));
        _;
    }

    /**
    * @dev Checks if msg.sender is allowed to create proposal under given category
    */
    modifier isAllowed(uint _categoryId) {
        require(allowedToCreateProposal(_categoryId), "Not allowed");
        _;
    }

    /**
    * @dev Checks if msg.sender is allowed categorize proposal under given category
    */
    modifier isAllowedToCategorize() {
        require(memberRole.checkRole(msg.sender, roleIdAllowedToCatgorize), "Not allowed");
        _;
    }

    /**
    * @dev Checks if msg.sender had any pending rewards to be claimed
    */
    modifier checkPendingRewards {
        require(getPendingReward(msg.sender) == 0, "Claim reward");
        _;
    }

    /**
    * @dev Event emitted whenever a proposal is categorized
    */
    event ProposalCategorized(
        uint indexed proposalId,
        address indexed categorizedBy,
        uint categoryId
    );
    
    /**
     * @dev Removes delegation of an address.
     * @param _add address to undelegate.
     */
    function removeDelegation(address _add) external onlyInternal {
        _unDelegate(_add);
    }

    /**
    * @dev Creates a new proposal
    * @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    * @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    */
    function createProposal(
        string calldata _proposalTitle, 
        string calldata _proposalSD, 
        string calldata _proposalDescHash, 
        uint _categoryId
    ) 
        external isAllowed(_categoryId)
    {
        require(ms.isMember(msg.sender), "Not Member");

        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);
    }

    /**
    * @dev Edits the details of an existing proposal
    * @param _proposalId Proposal id that details needs to be updated
    * @param _proposalDescHash Proposal description hash having long and short description of proposal.
    */
    function updateProposal(
        uint _proposalId, 
        string calldata _proposalTitle, 
        string calldata _proposalSD, 
        string calldata _proposalDescHash
    ) 
        external onlyProposalOwner(_proposalId)
    {
        require(
            allProposalSolutions[_proposalId].length < 2,
            "Not allowed"
        );
        allProposalData[_proposalId].propStatus = uint(ProposalStatus.Draft);
        allProposalData[_proposalId].category = 0;
        allProposalData[_proposalId].commonIncentive = 0;
        emit Proposal(
            allProposalData[_proposalId].owner,
            _proposalId,
            now,
            _proposalTitle, 
            _proposalSD, 
            _proposalDescHash
        );
    }

    /**
    * @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    */
    function categorizeProposal(
        uint _proposalId,
        uint _categoryId,
        uint _incentive
    )
        external
        voteNotStarted(_proposalId) isAllowedToCategorize
    {
        _categorizeProposal(_proposalId, _categoryId, _incentive);
    }

    /**
    * @dev Initiates add solution
    * To implement the governance interface
    */
    function addSolution(uint, string calldata, bytes calldata) external {
    }

    /**
    * @dev Opens proposal for voting
    * To implement the governance interface
    */
    function openProposalForVoting(uint) external {
    }

    /**
    * @dev Submit proposal with solution
    * @param _proposalId Proposal id
    * @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    */
    function submitProposalWithSolution(
        uint _proposalId, 
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external
        onlyProposalOwner(_proposalId)
    {

        require(allProposalData[_proposalId].propStatus == uint(ProposalStatus.AwaitingSolution));
        
        _proposalSubmission(_proposalId, _solutionHash, _action);
    }

    /**
    * @dev Creates a new proposal with solution
    * @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    * @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    * @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    */
    function createProposalwithSolution(
        string calldata _proposalTitle, 
        string calldata _proposalSD, 
        string calldata _proposalDescHash,
        uint _categoryId, 
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external isAllowed(_categoryId)
    {


        uint proposalId = totalProposals;

        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);
        
        require(_categoryId > 0);

        _proposalSubmission(
            proposalId,
            _solutionHash,
            _action
        );
    }

    /**
     * @dev Submit a vote on the proposal.
     * @param _proposalId to vote upon.
     * @param _solutionChosen is the chosen vote.
     */
    function submitVote(uint _proposalId, uint _solutionChosen) external {
        
        require(allProposalData[_proposalId].propStatus == 
        uint(Governance.ProposalStatus.VotingStarted), "Not allowed");

        require(_solutionChosen < allProposalSolutions[_proposalId].length);


        _submitVote(_proposalId, _solutionChosen);
    }

    /**
     * @dev Closes the proposal.
     * @param _proposalId of proposal to be closed.
     */
    function closeProposal(uint _proposalId) external {
        uint category = allProposalData[_proposalId].category;
        
        
        uint _memberRole;
        if (allProposalData[_proposalId].dateUpd.add(maxDraftTime) <= now && 
            allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted)) {
            _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
        } else {
            require(canCloseProposal(_proposalId) == 1);
            (, _memberRole, , , , , ) = proposalCategory.category(allProposalData[_proposalId].category);
            if (_memberRole == uint(MemberRoles.Role.AdvisoryBoard)) {
                _closeAdvisoryBoardVote(_proposalId, category);
            } else {
                _closeMemberVote(_proposalId, category);
            }
        }
        
    }

    /**
     * @dev Claims reward for member.
     * @param _memberAddress to claim reward of.
     * @param _maxRecords maximum number of records to claim reward for.
     _proposals list of proposals of which reward will be claimed.
     * @return amount of pending reward.
     */
    function claimReward(address _memberAddress, uint _maxRecords) 
        external returns(uint pendingDAppReward) 
    {
        
        uint voteId;
        address leader;
        uint lastUpd;

        require(msg.sender == ms.getLatestAddress("CR"));

        uint delegationId = followerDelegation[_memberAddress];
        DelegateVote memory delegationData = allDelegation[delegationId];
        if (delegationId > 0 && delegationData.leader != address(0)) {
            leader = delegationData.leader;
            lastUpd = delegationData.lastUpd;
        } else
            leader = _memberAddress;

        uint proposalId;
        uint totalVotes = allVotesByMember[leader].length;
        uint lastClaimed = totalVotes;
        uint j;
        uint i;
        for (i = lastRewardClaimed[_memberAddress]; i < totalVotes && j < _maxRecords; i++) {
            voteId = allVotesByMember[leader][i];
            proposalId = allVotes[voteId].proposalId;
            if (proposalVoteTally[proposalId].voters > 0 && (allVotes[voteId].dateAdd > (
                lastUpd.add(tokenHoldingTime)) || leader == _memberAddress)) {
                if (allProposalData[proposalId].propStatus > uint(ProposalStatus.VotingStarted)) {
                    if (!rewardClaimed[voteId][_memberAddress]) {
                        pendingDAppReward = pendingDAppReward.add(
                                allProposalData[proposalId].commonIncentive.div(
                                    proposalVoteTally[proposalId].voters
                                )
                            );
                        rewardClaimed[voteId][_memberAddress] = true;
                        j++;
                    }
                } else {
                    if (lastClaimed == totalVotes) {
                        lastClaimed = i;
                    }
                }
            }
        }

        if (lastClaimed == totalVotes) {
            lastRewardClaimed[_memberAddress] = i;
        } else {
            lastRewardClaimed[_memberAddress] = lastClaimed;
        }

        if (j > 0) {
            emit RewardClaimed(
                _memberAddress,
                pendingDAppReward
            );
        }
    }

    /**
     * @dev Sets delegation acceptance status of individual user
     * @param _status delegation acceptance status
     */
    function setDelegationStatus(bool _status) external isMemberAndcheckPause checkPendingRewards {
        isOpenForDelegation[msg.sender] = _status;
    }

    /**
     * @dev Delegates vote to an address.
     * @param _add is the address to delegate vote to.
     */
    function delegateVote(address _add) external isMemberAndcheckPause checkPendingRewards {

        require(ms.masterInitialized());

        require(allDelegation[followerDelegation[_add]].leader == address(0));

        if (followerDelegation[msg.sender] > 0) {
            require((allDelegation[followerDelegation[msg.sender]].lastUpd).add(tokenHoldingTime) < now);
        }

        require(!alreadyDelegated(msg.sender));
        require(!memberRole.checkRole(msg.sender, uint(MemberRoles.Role.Owner)));
        require(!memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)));


        require(followerCount[_add] < maxFollowers);
        
        if (allVotesByMember[msg.sender].length > 0) {
            require((allVotes[allVotesByMember[msg.sender][allVotesByMember[msg.sender].length - 1]].dateAdd).add(tokenHoldingTime)
            < now);
        }

        require(ms.isMember(_add));

        require(isOpenForDelegation[_add]);

        allDelegation.push(DelegateVote(msg.sender, _add, now));
        followerDelegation[msg.sender] = allDelegation.length - 1;
        leaderDelegation[_add].push(allDelegation.length - 1);
        followerCount[_add]++;
        lastRewardClaimed[msg.sender] = allVotesByMember[_add].length;
    }

    /**
     * @dev Undelegates the sender
     */
    function unDelegate() external isMemberAndcheckPause checkPendingRewards {
        _unDelegate(msg.sender);
    }

    /**
     * @dev Triggers action of accepted proposal after waiting time is finished
     */
    function triggerAction(uint _proposalId) external {
        require(proposalActionStatus[_proposalId] == uint(ActionStatus.Accepted) && proposalExecutionTime[_proposalId] <= now, "Cannot trigger");
        _triggerAction(_proposalId, allProposalData[_proposalId].category);
    }

    /**
     * @dev Provides option to Advisory board member to reject proposal action execution within actionWaitingTime, if found suspicious
     */
    function rejectAction(uint _proposalId) external {
        require(memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)) && proposalExecutionTime[_proposalId] > now);

        require(proposalActionStatus[_proposalId] == uint(ActionStatus.Accepted));

        require(!proposalRejectedByAB[_proposalId][msg.sender]);

        require(
            keccak256(proposalCategory.categoryActionHashes(allProposalData[_proposalId].category))
            != keccak256(abi.encodeWithSignature("swapABMember(address,address)"))
        );

        proposalRejectedByAB[_proposalId][msg.sender] = true;
        actionRejectedCount[_proposalId]++;
        emit ActionRejected(_proposalId, msg.sender);
        if (actionRejectedCount[_proposalId] == AB_MAJ_TO_REJECT_ACTION) {
            proposalActionStatus[_proposalId] = uint(ActionStatus.Rejected);
        }
    }

    /**
     * @dev Sets intial actionWaitingTime value
     * To be called after governance implementation has been updated
     */
    function setInitialActionParameters() external onlyOwner {
        require(!actionParamsInitialised);
        actionParamsInitialised = true;
        actionWaitingTime = 24 * 1 hours;
    }

    /**
     * @dev Gets Uint Parameters of a code
     * @param code whose details we want
     * @return string value of the code
     * @return associated amount (time or perc or value) to the code
     */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {

        codeVal = code;

        if (code == "GOVHOLD") {

            val = tokenHoldingTime / (1 days);

        } else if (code == "MAXFOL") {

            val = maxFollowers;

        } else if (code == "MAXDRFT") {

            val = maxDraftTime / (1 days);

        } else if (code == "EPTIME") {

            val = ms.pauseTime() / (1 days);

        } else if (code == "ACWT") {

            val = actionWaitingTime / (1 hours);

        }
    }

    /**
     * @dev Gets all details of a propsal
     * @param _proposalId whose details we want
     * @return proposalId
     * @return category
     * @return status
     * @return finalVerdict
     * @return totalReward
     */
    function proposal(uint _proposalId)
        external
        view
        returns(
            uint proposalId,
            uint category,
            uint status,
            uint finalVerdict,
            uint totalRewar
        )
    {
        return(
            _proposalId,
            allProposalData[_proposalId].category,
            allProposalData[_proposalId].propStatus,
            allProposalData[_proposalId].finalVerdict,
            allProposalData[_proposalId].commonIncentive
        );
    }

    /**
     * @dev Gets some details of a propsal
     * @param _proposalId whose details we want
     * @return proposalId
     * @return number of all proposal solutions
     * @return amount of votes 
     */
    function proposalDetails(uint _proposalId) external view returns(uint, uint, uint) {
        return(
            _proposalId,
            allProposalSolutions[_proposalId].length,
            proposalVoteTally[_proposalId].voters
        );
    }

    /**
     * @dev Gets solution action on a proposal
     * @param _proposalId whose details we want
     * @param _solution whose details we want
     * @return action of a solution on a proposal
     */
    function getSolutionAction(uint _proposalId, uint _solution) external view returns(uint, bytes memory) {
        return (
            _solution,
            allProposalSolutions[_proposalId][_solution]
        );
    }
   
    /**
     * @dev Gets length of propsal
     * @return length of propsal
     */
    function getProposalLength() external view returns(uint) {
        return totalProposals;
    }

    /**
     * @dev Get followers of an address
     * @return get followers of an address
     */
    function getFollowers(address _add) external view returns(uint[] memory) {
        return leaderDelegation[_add];
    }

    /**
     * @dev Gets pending rewards of a member
     * @param _memberAddress in concern
     * @return amount of pending reward
     */
    function getPendingReward(address _memberAddress)
        public view returns(uint pendingDAppReward)
    {
        uint delegationId = followerDelegation[_memberAddress];
        address leader;
        uint lastUpd;
        DelegateVote memory delegationData = allDelegation[delegationId];

        if (delegationId > 0 && delegationData.leader != address(0)) {
            leader = delegationData.leader;
            lastUpd = delegationData.lastUpd;
        } else
            leader = _memberAddress;

        uint proposalId;
        for (uint i = lastRewardClaimed[_memberAddress]; i < allVotesByMember[leader].length; i++) {
            if (allVotes[allVotesByMember[leader][i]].dateAdd > (
                lastUpd.add(tokenHoldingTime)) || leader == _memberAddress) {
                if (!rewardClaimed[allVotesByMember[leader][i]][_memberAddress]) {
                    proposalId = allVotes[allVotesByMember[leader][i]].proposalId;
                    if (proposalVoteTally[proposalId].voters > 0 && allProposalData[proposalId].propStatus
                    > uint(ProposalStatus.VotingStarted)) {
                        pendingDAppReward = pendingDAppReward.add(
                            allProposalData[proposalId].commonIncentive.div(
                                proposalVoteTally[proposalId].voters
                            )
                        );
                    }
                }
            }
        }
    }

    /**
     * @dev Updates Uint Parameters of a code
     * @param code whose details we want to update
     * @param val value to set
     */
    function updateUintParameters(bytes8 code, uint val) public {

        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "GOVHOLD") {

            tokenHoldingTime = val * 1 days;

        } else if (code == "MAXFOL") {

            maxFollowers = val;

        } else if (code == "MAXDRFT") {

            maxDraftTime = val * 1 days;

        } else if (code == "EPTIME") {

            ms.updatePauseTime(val * 1 days);

        } else if (code == "ACWT") {

            actionWaitingTime = val * 1 hours;

        } else {

            revert("Invalid code");

        }
    }

    /**
    * @dev Updates all dependency addresses to latest ones from Master
    */
    function changeDependentContractAddress() public {
        tokenInstance = TokenController(ms.dAppLocker());
        memberRole = MemberRoles(ms.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(ms.getLatestAddress("PC"));
    }

    /**
    * @dev Checks if msg.sender is allowed to create a proposal under given category
    */
    function allowedToCreateProposal(uint category) public view returns(bool check) {
        if (category == 0)
            return true;
        uint[] memory mrAllowed;
        (, , , , mrAllowed, , ) = proposalCategory.category(category);
        for (uint i = 0; i < mrAllowed.length; i++) {
            if (mrAllowed[i] == 0 || memberRole.checkRole(msg.sender, mrAllowed[i]))
                return true;
        }
    }

    /**
     * @dev Checks if an address is already delegated
     * @param _add in concern
     * @return bool value if the address is delegated or not
     */
    function alreadyDelegated(address _add) public view returns(bool delegated) {
        for (uint i=0; i < leaderDelegation[_add].length; i++) {
            if (allDelegation[leaderDelegation[_add][i]].leader == _add) {
                return true;
            }
        }
    }

    /**
    * @dev Pauses a proposal
    * To implement govblocks interface
    */
    function pauseProposal(uint) public {
    }

    /**
    * @dev Resumes a proposal
    * To implement govblocks interface
    */
    function resumeProposal(uint) public {
    }

    /**
    * @dev Checks If the proposal voting time is up and it's ready to close 
    *      i.e. Closevalue is 1 if proposal is ready to be closed, 2 if already closed, 0 otherwise!
    * @param _proposalId Proposal id to which closing value is being checked
    */
    function canCloseProposal(uint _proposalId) 
        public 
        view 
        returns(uint)
    {
        uint dateUpdate;
        uint pStatus;
        uint _closingTime;
        uint _roleId;
        uint majority;
        pStatus = allProposalData[_proposalId].propStatus;
        dateUpdate = allProposalData[_proposalId].dateUpd;
        (, _roleId, majority, , , _closingTime, ) = proposalCategory.category(allProposalData[_proposalId].category);
        if (
            pStatus == uint(ProposalStatus.VotingStarted)
        ) {
            uint numberOfMembers = memberRole.numberOfMembers(_roleId);
            if (_roleId == uint(MemberRoles.Role.AdvisoryBoard)) {
                if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100).div(numberOfMembers) >= majority  
                || proposalVoteTally[_proposalId].abVoteValue[1].add(proposalVoteTally[_proposalId].abVoteValue[0]) == numberOfMembers
                || dateUpdate.add(_closingTime) <= now) {

                    return 1;
                }
            } else {
                if (numberOfMembers == proposalVoteTally[_proposalId].voters 
                || dateUpdate.add(_closingTime) <= now)
                    return  1;
            }
        } else if (pStatus > uint(ProposalStatus.VotingStarted)) {
            return  2;
        } else {
            return  0;
        }
    }

    /**
     * @dev Gets Id of member role allowed to categorize the proposal
     * @return roleId allowed to categorize the proposal
     */
    function allowedToCatgorize() public view returns(uint roleId) {
        return roleIdAllowedToCatgorize;
    }

    /**
     * @dev Gets vote tally data
     * @param _proposalId in concern
     * @param _solution of a proposal id
     * @return member vote value
     * @return advisory board vote value
     * @return amount of votes
     */
    function voteTallyData(uint _proposalId, uint _solution) public view returns(uint, uint, uint) {
        return (proposalVoteTally[_proposalId].memberVoteValue[_solution],
            proposalVoteTally[_proposalId].abVoteValue[_solution], proposalVoteTally[_proposalId].voters);
    }

    /**
     * @dev Internal call to create proposal
     * @param _proposalTitle of proposal
     * @param _proposalSD is short description of proposal
     * @param _proposalDescHash IPFS hash value of propsal
     * @param _categoryId of proposal
     */
    function _createProposal(
        string memory _proposalTitle,
        string memory _proposalSD,
        string memory _proposalDescHash,
        uint _categoryId
    )
        internal
    {
        require(proposalCategory.categoryABReq(_categoryId) == 0 || _categoryId == 0);
        uint _proposalId = totalProposals;
        allProposalData[_proposalId].owner = msg.sender;
        allProposalData[_proposalId].dateUpd = now;
        allProposalSolutions[_proposalId].push("");
        totalProposals++;

        emit Proposal(
            msg.sender,
            _proposalId,
            now,
            _proposalTitle,
            _proposalSD,
            _proposalDescHash
        );

        if (_categoryId > 0)
            _categorizeProposal(_proposalId, _categoryId, 0);
    }

    /**
     * @dev Internal call to categorize a proposal
     * @param _proposalId of proposal
     * @param _categoryId of proposal
     * @param _incentive is commonIncentive
     */
    function _categorizeProposal(
        uint _proposalId,
        uint _categoryId,
        uint _incentive
    )
        internal
    {
        require(
            _categoryId > 0 && _categoryId < proposalCategory.totalCategories(),
            "Invalid category"
        );
        allProposalData[_proposalId].category = _categoryId;
        allProposalData[_proposalId].commonIncentive = _incentive;
        allProposalData[_proposalId].propStatus = uint(ProposalStatus.AwaitingSolution);

        emit ProposalCategorized(_proposalId, msg.sender, _categoryId);
    }

    /**
     * @dev Internal call to add solution to a proposal
     * @param _proposalId in concern
     * @param _action on that solution
     * @param _solutionHash string value
     */
    function _addSolution(uint _proposalId, bytes memory _action, string memory _solutionHash)
        internal
    {
        allProposalSolutions[_proposalId].push(_action);
        emit Solution(_proposalId, msg.sender, allProposalSolutions[_proposalId].length - 1, _solutionHash, now);
    }

    /**
    * @dev Internal call to add solution and open proposal for voting
    */
    function _proposalSubmission(
        uint _proposalId,
        string memory _solutionHash,
        bytes memory _action
    )
        internal
    {

        uint _categoryId = allProposalData[_proposalId].category;
        if (proposalCategory.categoryActionHashes(_categoryId).length == 0) {
            require(keccak256(_action) == keccak256(""));
            proposalActionStatus[_proposalId] = uint(ActionStatus.NoAction);
        }
        
        _addSolution(
            _proposalId,
            _action,
            _solutionHash
        );

        _updateProposalStatus(_proposalId, uint(ProposalStatus.VotingStarted));
        (, , , , , uint closingTime, ) = proposalCategory.category(_categoryId);
        emit CloseProposalOnTime(_proposalId, closingTime.add(now));

    }

    /**
     * @dev Internal call to submit vote
     * @param _proposalId of proposal in concern
     * @param _solution for that proposal
     */
    function _submitVote(uint _proposalId, uint _solution) internal {

        uint delegationId = followerDelegation[msg.sender];
        uint mrSequence;
        uint majority;
        uint closingTime;
        (, mrSequence, majority, , , closingTime, ) = proposalCategory.category(allProposalData[_proposalId].category);

        require(allProposalData[_proposalId].dateUpd.add(closingTime) > now, "Closed");

        require(memberProposalVote[msg.sender][_proposalId] == 0, "Not allowed");
        require((delegationId == 0) || (delegationId > 0 && allDelegation[delegationId].leader == address(0) && 
        _checkLastUpd(allDelegation[delegationId].lastUpd)));

        require(memberRole.checkRole(msg.sender, mrSequence), "Not Authorized");
        uint totalVotes = allVotes.length;

        allVotesByMember[msg.sender].push(totalVotes);
        memberProposalVote[msg.sender][_proposalId] = totalVotes;

        allVotes.push(ProposalVote(msg.sender, _proposalId, now));

        emit Vote(msg.sender, _proposalId, totalVotes, now, _solution);
        if (mrSequence == uint(MemberRoles.Role.Owner)) {
            if (_solution == 1)
                _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), allProposalData[_proposalId].category, 1, MemberRoles.Role.Owner);
            else
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));
        
        } else {
            uint numberOfMembers = memberRole.numberOfMembers(mrSequence);
            _setVoteTally(_proposalId, _solution, mrSequence);

            if (mrSequence == uint(MemberRoles.Role.AdvisoryBoard)) {
                if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100).div(numberOfMembers) 
                >= majority 
                || (proposalVoteTally[_proposalId].abVoteValue[1].add(proposalVoteTally[_proposalId].abVoteValue[0])) == numberOfMembers) {
                    emit VoteCast(_proposalId);
                }
            } else {
                if (numberOfMembers == proposalVoteTally[_proposalId].voters)
                    emit VoteCast(_proposalId);
            }
        }

    }

    /**
     * @dev Internal call to set vote tally of a proposal
     * @param _proposalId of proposal in concern
     * @param _solution of proposal in concern
     * @param mrSequence number of members for a role
     */
    function _setVoteTally(uint _proposalId, uint _solution, uint mrSequence) internal
    {
        uint categoryABReq;
        uint isSpecialResolution;
        (, categoryABReq, isSpecialResolution) = proposalCategory.categoryExtendedData(allProposalData[_proposalId].category);
        if (memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)) && (categoryABReq > 0) || 
            mrSequence == uint(MemberRoles.Role.AdvisoryBoard)) {
            proposalVoteTally[_proposalId].abVoteValue[_solution]++;
        }
        tokenInstance.lockForMemberVote(msg.sender, tokenHoldingTime);
        if (mrSequence != uint(MemberRoles.Role.AdvisoryBoard)) {
            uint voteWeight;
            uint voters = 1;
            uint tokenBalance = tokenInstance.totalBalanceOf(msg.sender);
            uint totalSupply = tokenInstance.totalSupply();
            if (isSpecialResolution == 1) {
                voteWeight = tokenBalance.add(10**18);
            } else {
                voteWeight = (_minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100))).add(10**18);
            }
            DelegateVote memory delegationData;
            for (uint i = 0; i < leaderDelegation[msg.sender].length; i++) {
                delegationData = allDelegation[leaderDelegation[msg.sender][i]];
                if (delegationData.leader == msg.sender && 
                _checkLastUpd(delegationData.lastUpd)) {
                    if (memberRole.checkRole(delegationData.follower, mrSequence)) {
                        tokenBalance = tokenInstance.totalBalanceOf(delegationData.follower);
                        tokenInstance.lockForMemberVote(delegationData.follower, tokenHoldingTime);
                        voters++;
                        if (isSpecialResolution == 1) {
                            voteWeight = voteWeight.add(tokenBalance.add(10**18));
                        } else {
                            voteWeight = voteWeight.add((_minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100))).add(10**18));
                        }
                    }
                }
            }
            proposalVoteTally[_proposalId].memberVoteValue[_solution] = proposalVoteTally[_proposalId].memberVoteValue[_solution].add(voteWeight);
            proposalVoteTally[_proposalId].voters = proposalVoteTally[_proposalId].voters + voters;
        }
    }

    /**
     * @dev Gets minimum of two numbers
     * @param a one of the two numbers
     * @param b one of the two numbers
     * @return minimum number out of the two
     */
    function _minOf(uint a, uint b) internal pure returns(uint res) {
        res = a;
        if (res > b)
            res = b;
    }
    
    /**
     * @dev Check the time since last update has exceeded token holding time or not
     * @param _lastUpd is last update time
     * @return the bool which tells if the time since last update has exceeded token holding time or not
     */
    function _checkLastUpd(uint _lastUpd) internal view returns(bool) {
        return (now - _lastUpd) > tokenHoldingTime;
    }

    /**
    * @dev Checks if the vote count against any solution passes the threshold value or not.
    */
    function _checkForThreshold(uint _proposalId, uint _category) internal view returns(bool check) {
        uint categoryQuorumPerc;
        uint roleAuthorized;
        (, roleAuthorized, , categoryQuorumPerc, , , ) = proposalCategory.category(_category);
        check = ((proposalVoteTally[_proposalId].memberVoteValue[0]
                            .add(proposalVoteTally[_proposalId].memberVoteValue[1]))
                        .mul(100))
                .div(
                    tokenInstance.totalSupply().add(
                        memberRole.numberOfMembers(roleAuthorized).mul(10 ** 18)
                    )
                ) >= categoryQuorumPerc;
    }
    
    /**
     * @dev Called when vote majority is reached
     * @param _proposalId of proposal in concern
     * @param _status of proposal in concern
     * @param category of proposal in concern
     * @param max vote value of proposal in concern
     */
    function _callIfMajReached(uint _proposalId, uint _status, uint category, uint max, MemberRoles.Role role) internal {
        
        allProposalData[_proposalId].finalVerdict = max;
        _updateProposalStatus(_proposalId, _status);
        emit ProposalAccepted(_proposalId);
        if (proposalActionStatus[_proposalId] != uint(ActionStatus.NoAction)) {
            if (role == MemberRoles.Role.AdvisoryBoard) {
                _triggerAction(_proposalId, category);
            } else {
                proposalActionStatus[_proposalId] = uint(ActionStatus.Accepted);
                proposalExecutionTime[_proposalId] = actionWaitingTime.add(now);
            }
        }
    }

    /**
     * @dev Internal function to trigger action of accepted proposal
     */
    function _triggerAction(uint _proposalId, uint _categoryId) internal {
        proposalActionStatus[_proposalId] = uint(ActionStatus.Executed);
        bytes2 contractName;
        address actionAddress;
        bytes memory _functionHash;
        (, actionAddress, contractName, , _functionHash) = proposalCategory.categoryActionDetails(_categoryId);
        if (contractName == "MS") {
            actionAddress = address(ms);
        } else if (contractName != "EX") {
            actionAddress = ms.getLatestAddress(contractName);
        }
        (bool actionStatus, ) = actionAddress.call(abi.encodePacked(_functionHash, allProposalSolutions[_proposalId][1]));
        if (actionStatus) {
            emit ActionSuccess(_proposalId);
        } else {
            proposalActionStatus[_proposalId] = uint(ActionStatus.Accepted);
            emit ActionFailed(_proposalId);
        }
    }

    /**
     * @dev Internal call to update proposal status
     * @param _proposalId of proposal in concern
     * @param _status of proposal to set
     */
    function _updateProposalStatus(uint _proposalId, uint _status) internal {
        if (_status == uint(ProposalStatus.Rejected) || _status == uint(ProposalStatus.Denied)) {
            proposalActionStatus[_proposalId] = uint(ActionStatus.NoAction);   
        }
        allProposalData[_proposalId].dateUpd = now;
        allProposalData[_proposalId].propStatus = _status;
    }

    /**
     * @dev Internal call to undelegate a follower
     * @param _follower is address of follower to undelegate
     */
    function _unDelegate(address _follower) internal {
        uint followerId = followerDelegation[_follower];
        if (followerId > 0) {

            followerCount[allDelegation[followerId].leader] = followerCount[allDelegation[followerId].leader].sub(1);
            allDelegation[followerId].leader = address(0);
            allDelegation[followerId].lastUpd = now;

            lastRewardClaimed[_follower] = allVotesByMember[_follower].length;
        }
    }

    /**
     * @dev Internal call to close member voting
     * @param _proposalId of proposal in concern
     * @param category of proposal in concern
     */
    function _closeMemberVote(uint _proposalId, uint category) internal {
        uint isSpecialResolution;
        uint abMaj;
        (, abMaj, isSpecialResolution) = proposalCategory.categoryExtendedData(category);
        if (isSpecialResolution == 1) {
            uint acceptedVotePerc = proposalVoteTally[_proposalId].memberVoteValue[1].mul(100)
            .div(
                tokenInstance.totalSupply().add(
                        memberRole.numberOfMembers(uint(MemberRoles.Role.Member)).mul(10**18)
                    ));
            if (acceptedVotePerc >= specialResolutionMajPerc) {
                _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
            } else {
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
            }
        } else {
            if (_checkForThreshold(_proposalId, category)) {
                uint majorityVote;
                (, , majorityVote, , , , ) = proposalCategory.category(category);
                if (
                    ((proposalVoteTally[_proposalId].memberVoteValue[1].mul(100))
                                        .div(proposalVoteTally[_proposalId].memberVoteValue[0]
                                                .add(proposalVoteTally[_proposalId].memberVoteValue[1])
                                        ))
                    >= majorityVote
                    ) {
                        _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
                    } else {
                        _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));
                    }
            } else {
                if (abMaj > 0 && proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
                .div(memberRole.numberOfMembers(uint(MemberRoles.Role.AdvisoryBoard))) >= abMaj) {
                    _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
                } else {
                    _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
                }
            }
        }

        if (proposalVoteTally[_proposalId].voters > 0) {
            tokenInstance.mint(ms.getLatestAddress("CR"), allProposalData[_proposalId].commonIncentive);
        }
    }

    /**
     * @dev Internal call to close advisory board voting
     * @param _proposalId of proposal in concern
     * @param category of proposal in concern
     */
    function _closeAdvisoryBoardVote(uint _proposalId, uint category) internal {
        uint _majorityVote;
        MemberRoles.Role _roleId = MemberRoles.Role.AdvisoryBoard;
        (, , _majorityVote, , , , ) = proposalCategory.category(category);
        if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
        .div(memberRole.numberOfMembers(uint(_roleId))) >= _majorityVote) {
            _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, _roleId);
        } else {
            _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
        }

    }

}