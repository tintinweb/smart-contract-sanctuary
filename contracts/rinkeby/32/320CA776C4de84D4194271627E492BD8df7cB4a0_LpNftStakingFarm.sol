//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ERC20Interface.sol";
import "./IUniswapV2Pair.sol";
import "./Calculator.sol";
import "./erc1155/ERC1155TokenReceiver.sol";

/**
 * lp nft staking farm
 */
contract LpNftStakingFarm is
    Context,
    Ownable,
    ReentrancyGuard,
    Pausable,
    ERC1155TokenReceiver
{
    using Address for address;
    using SafeMath for uint256;
    using Calculator for uint256;

    /**
     * Emitted when a user store farming rewards(ERC20 token).
     * @param sender User address.
     * @param amount Current store amount.
     * @param timestamp The time when store farming rewards.
     */
    event ContractFunded(
        address indexed sender,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * Emitted when a user stakes tokens(ERC20 token).
     * @param sender User address.
     * @param balance Current user balance.
     * @param timestamp The time when stake tokens.
     */
    event Staked(address indexed sender, uint256 balance, uint256 timestamp);

    /**
     * Emitted when a user unstakes erc20 tokens.
     * @param sender User address.
     * @param apy The apy of user.
     * @param balance The balance of user.
     * @param umiInterest The amount of interest(umi token).
     * @param timePassed TimePassed seconds.
     * @param timestamp The time when unstake tokens.
     */
    event Unstaked(
        address indexed sender,
        uint256 apy,
        uint256 balance,
        uint256 umiInterest,
        uint256 timePassed,
        uint256 timestamp
    );

    /**
     * Emitted when a new BASE_APY value is set.
     * @param value A new APY value.
     * @param sender The owner address at the moment of BASE_APY changing.
     */
    event BaseApySet(uint256 value, address sender);

    /**
     * Emitted when a new nft apy value is set.
     * @param nftAddress The address of nft contract.
     * @param nftId The nft id.
     * @param value A new APY value.
     * @param sender The owner address at the moment of apy changing.
     */
    event NftApySet(address indexed nftAddress, uint256 nftId, uint256 value, address sender);

    /**
     * Emitted when a user stakes nft token.
     * @param sender User address.
     * @param nftAddress The address of nft contract.
     * @param nftId The nft id.
     * @param amount The amount of nft id.
     * @param timestamp The time when stake nft.
     */
    event NftStaked(
        address indexed sender,
        address indexed nftAddress,
        uint256 nftId,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * Emitted when a user batch stakes nft token.
     * @param sender User address.
     * @param nftAddress The address of nft contract.
     * @param nftIds The nft id.
     * @param amounts The amount of nft id.
     * @param timestamp The time when batch stake nft.
     */
    event NftsBatchStaked(
        address indexed sender,
        address indexed nftAddress,
        uint256[] nftIds,
        uint256[] amounts,
        uint256 timestamp
    );

    /**
     * Emitted when a user unstake nft token.
     * @param sender User address.
     * @param nftAddress The address of nft contract.
     * @param nftId The nft id.
     * @param amount The amount of nft id.
     * @param timestamp The time when unstake nft.
     */
    event NftUnstaked(
        address indexed sender,
        address indexed nftAddress,
        uint256 nftId,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * Emitted when a user batch unstake nft token.
     * @param sender User address.
     * @param nftAddress The address of nft contract.
     * @param nftIds The nft id array.
     * @param amounts The amount array of nft id.
     * @param timestamp The time when batch unstake nft.
     */
    event NftsBatchUnstaked(
        address indexed sender,
        address indexed nftAddress,
        uint256[] nftIds,
        uint256[] amounts,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a user withdraw interest only.
     * @param sender User address.
     * @param principal The principal of user.
     * @param interest The amount of interest.
     * @param claimTimestamp claim timestamp.
     */
    event Claimed(
        address indexed sender,
        uint256 principal,
        uint256 interest,
        uint256 claimTimestamp
    );

    // lp token
    IUniswapV2Pair public lpToken;
    // rewards token(umi token now)
    ERC20Interface public umiToken;

    // lp token about
    // The stake balances of users, it will contains interest(user address->amount), input token is umi
    mapping(address => uint256) public balances;
    // The dates of users' stakes(user address->timestamp)
    mapping(address => uint256) public stakeDates;
    // The total staked amount
    uint256 public totalStaked;

    // umi token about
    // The farming rewards of users(address => total amount)
    mapping(address => uint256) public funding;
    // The total farming rewards for users
    uint256 public totalFunding;

    // ERC1155 about
    // Store each nft apy(nft address->(ntfId->apy))
    mapping(address => mapping(uint256 => uint8)) public nftApys;
    // Nft balance of users(user address->(nft contract address -> (nftId->amount)))
    mapping(address => mapping(address => mapping(uint256 => uint256))) public nftBalances;
    // Store user's nft ids(user address -> (nft contract address -> NftSet))
    mapping(address => mapping(address => NftSet)) userNftIds;
    // The total nft staked amount
    uint256 public totalNftStaked;
    // To store user's nft ids, it is more convenient to know if nft id of user exists
    struct NftSet {
        // user's nft id array
        uint256[] ids;
        // nft id -> bool, if nft id exist
        mapping(uint256 => bool) isIn;
    }
    // the nft contracts address which supported
    address[] public nftAddresses;
    // if nft address supported
    mapping(address => bool) public isNftSupported;
    address private firstNft = 0xAA0d091C775Ba170E8f9A198fCD3d51636F0e8b3;
    address private secondNft = 0xe2EC046Fd4431301E72d1E03ed578C804cA9E8F3;

    // other constants
    // base APY when staking just lp token is 33%, only contract owner can modify it
    uint256 public BASE_APY = 33; // stand for 33%

    constructor(address _umiAddress, address _lpAddress) {
        require(
            _umiAddress.isContract() && _lpAddress.isContract(),
            "must use contract address"
        );
        umiToken = ERC20Interface(_umiAddress);
        lpToken = IUniswapV2Pair(_lpAddress);
        
        nftAddresses.push(firstNft);
        nftAddresses.push(secondNft);
        isNftSupported[firstNft] = true;
        isNftSupported[secondNft] = true;
        
        // initialize apys
        initApys();
    }

    /**
     * Store farming rewards to UmiStakingFarm contract, in order to pay the user interest later.
     *
     * Note: _amount should be more than 0
     * @param _amount The amount to funding contract.
     */
    function fundingContract(uint256 _amount) external nonReentrant {
        require(_amount > 0, "_amount should be more than 0");
        funding[msg.sender] += _amount;
        // increase total funding
        totalFunding += _amount;
        require(
            umiToken.transferFrom(msg.sender, address(this), _amount),
            "transferFrom failed"
        );
        // send event
        emit ContractFunded(msg.sender, _amount, _now());
    }

    /**
     * Only owner can set base apy.
     *
     * Note: If you want to set apy 12%, just pass 12
     *
     * @param _APY annual percentage yield
     */
    function setBaseApy(uint256 _APY) public onlyOwner {
        BASE_APY = _APY;
        emit BaseApySet(BASE_APY, msg.sender);
    }

    /**
     * This method is used to stake tokens(input token is LpToken).
     * Note: It calls another internal "_stake" method. See its description.
     * @param _amount The amount to stake.
     */
    function stake(uint256 _amount) public whenNotPaused nonReentrant {
        _stake(msg.sender, _amount);
    }

    /**
     * Increases the user's balance, totalStaked and updates the stake date.
     * @param _sender The address of the sender.
     * @param _amount The amount to stake.
     */
    function _stake(address _sender, uint256 _amount) internal {
        require(_amount > 0, "stake amount should be more than 0");
        // calculate rewards of umi token
        uint256 umiInterest = calculateUmiTokenRewards(_sender);

        // increase balances
        balances[_sender] = balances[_sender].add(_amount);
        // increase totalStaked
        totalStaked = totalStaked.add(_amount);
        uint256 stakeTimestamp = _now();
        stakeDates[_sender] = stakeTimestamp;
        // send staked event
        emit Staked(_sender, _amount, stakeTimestamp);
        // transfer lp token to contract
        require(
            lpToken.transferFrom(_sender, address(this), _amount),
            "transfer failed"
        );
        // Transfer umiToken interest to user
        transferUmiInterest(_sender, umiInterest);
    }
    
    /**
     * Transfer umiToken interest to user.
     */ 
    function transferUmiInterest(address recipient, uint256 amount) internal {
        if (amount <= 0) {
            return;
        }
        // reduce total funding
        totalFunding = totalFunding.sub(amount);
        require(
                umiToken.transfer(recipient, amount),
                "transfer umi interest failed"
            );
    }

    /**
     * This method is used to unstake all the amount of lp token.
     * Note: It calls another internal "_unstake" method. See its description.
     * Note: unstake lp token.
     */
    function unstake() external whenNotPaused nonReentrant {
        _unstake(msg.sender);
    }

    /**
     * Call internal "calculateRewardsAndTimePassed" method to calculate user's latest balance,
     * and then transfer tokens to the sender.
     *
     * @param _sender The address of the sender.
     */
    function _unstake(address _sender) internal {
        // get lp token balance of current user
        uint256 balance = balances[msg.sender];
        require(balance > 0, "insufficient funds");
        // calculate total balance with interest(the interest is umi token)
        (uint256 totalWithInterest, uint256 principalOfRepresentUmi, uint256 timePassed) =
            calculateRewardsAndTimePassed(_sender, 0);
        require(
            totalWithInterest > 0 && timePassed > 0,
            "totalWithInterest<=0 or timePassed<=0"
        );
        // update balance of user to 0
        balances[_sender] = 0;
        // update date of stake
        stakeDates[_sender] = 0;
        // update totalStaked of lpToken
        totalStaked = totalStaked.sub(balance);

        // interest to be paid, rewards is umi token
        uint256 interest = totalWithInterest.sub(principalOfRepresentUmi);
        uint256 umiInterestAmount = 0;
        if (interest > 0 && totalFunding >= interest) {
            // interest > 0 and total funding is enough to pay interest
            umiInterestAmount = interest;
            // reduce total funding
            totalFunding = totalFunding.sub(interest);
        }
        // total funding is not enough to pay interest, the contract's UMI has been completely drained. make sure users can unstake their lp tokens.
        // 1. rewards are paid in more umi
        if (umiInterestAmount > 0) {
            require(
                umiToken.transfer(_sender, umiInterestAmount),
                "_unstake umi transfer failed"
            );
        }
        // 2. unstake lp token of user
        require(
            lpToken.transfer(_sender, balance),
            "_unstake: lp transfer failed"
        );
        // send event
        emit Unstaked(
            _sender,
            getTotalApyOfUser(_sender),
            balance,
            umiInterestAmount,
            timePassed,
            _now()
        );
    }

    /**
     * stake nft token to this contract.
     * Note: It calls another internal "_stakeNft" method. See its description.
     * 
     * @param nftAddress The address of nft contract.
     */
    function stakeNft(
        address nftAddress,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external whenNotPaused nonReentrant {
        require(isInWhitelist(nftAddress, id), "stakeNft: nft id not in whitelist");
        _stakeNft(msg.sender, address(this), nftAddress, id, value, data);
    }

    /**
     * Transfers `_value` tokens of token type `_id` from `_from` to `_to`.
     *
     * Note: when nft staked, apy will changed, should recalculate balance.
     * update nft balance, nft id, totalNftStaked.
     *
     * @param _from The address of the sender.
     * @param _to The address of the receiver.
     * @param _nftAddress The address of nft contract.
     * @param _id The nft id.
     * @param _value The amount of nft token.
     */
    function _stakeNft(
        address _from,
        address _to,
        address _nftAddress,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) internal {
        // calculate rewards of umi token
        uint256 umiInterest = calculateUmiTokenRewards(_from);
        // update stakeDate of user
        stakeDates[_from] = balances[_from] > 0 ?  _now() : 0;

        // modify nftBalances of user
        nftBalances[_from][_nftAddress][_id] = nftBalances[_from][_nftAddress][_id].add(_value);
        // modify user's nft id array
        setUserNftIds(_from, _nftAddress, _id);
        totalNftStaked = totalNftStaked.add(_value);

        // transfer nft token to this contract
        getERC1155(_nftAddress).safeTransferFrom(_from, _to, _id, _value, _data);
        // Transfer umiToken interest to user
        transferUmiInterest(_from, umiInterest);
        // send event
        emit NftStaked(_from, _nftAddress, _id, _value, _now());
    }

    /**
     * Batch stake nft token to this contract.
     *
     * Note: It calls another internal "_batchStakeNfts" method. See its description.
     *       Reverts if ids and values length mismatch.
     * 
     * @param nftAddress The address of nft contract.
     * @param ids The nft id array to be staked.
     * @param values The nft amount array.
     */
    function batchStakeNfts(
        address nftAddress,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external whenNotPaused nonReentrant {
        require(
            ids.length == values.length,
            "ids and values length mismatch"
        );
        _batchStakeNfts(msg.sender, address(this), nftAddress, ids, values, data);
    }

    /**
     * Batch transfers `_values` tokens of token type `_ids` from `_from` to `_to`.
     *
     * Note: when nft staked, apy will changed, should recalculate balance.
     * update nft balance, nft id and totalNftStaked.
     *
     * @param _from The address of sender.
     * @param _to The address of receiver.
     * @param _nftAddress The address of nft contract.
     * @param _ids The nft id array to be staked.
     * @param _values The nft amount array.
     */
    function _batchStakeNfts(
        address _from,
        address _to,
        address _nftAddress,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes calldata _data
    ) internal {
        // calculate rewards of umi token
        uint256 umiInterest = calculateUmiTokenRewards(_from);
        // update stakeDate of user
        stakeDates[_from] = balances[_from] > 0 ?  _now() : 0;

        // update data
        for (uint256 i = 0; i < _ids.length; i++) {
            // get nft id from id array
            uint256 id = _ids[i];
            // get amount
            uint256 value = _values[i];

            require(isInWhitelist(_nftAddress, id), "nft id not in whitelist");

            // increase nft balance of user
            nftBalances[_from][_nftAddress][id] = nftBalances[_from][_nftAddress][id].add(value);
            // update user's nft id array
            setUserNftIds(_from, _nftAddress, id);
            // increase total nft amount
            totalNftStaked = totalNftStaked.add(value);
        }

        // batch transfer nft tokens
        getERC1155(_nftAddress).safeBatchTransferFrom(_from, _to, _ids, _values, _data);
        // Transfer umiToken interest to user
        transferUmiInterest(msg.sender, umiInterest);
        // send event
        emit NftsBatchStaked(_from, _nftAddress, _ids, _values, _now());
    }

    /**
     * Unstake nft token from this contract.
     *
     * Note: It calls another internal "_unstakeNft" method. See its description.
     *
     * @param nftAddress The address of nft contract.
     * @param id The nft id.
     * @param value The amount of nft id.
     */
    function unstakeNft(
        address nftAddress,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external whenNotPaused nonReentrant {
        _unstakeNft(nftAddress, id, value, data);
    }

    /**
     * Unstake nft token with sufficient balance.
     *
     * Note: when nft unstaked, apy will changed, should recalculate balance.
     * update nft balance, nft id and totalNftStaked.
     *
     * @param _nftAddress The address of nft contract.
     * @param _id The nft id.
     * @param _value The amount of nft id.
     */
    function _unstakeNft(
        address _nftAddress,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) internal {
        // calculate rewards of umi token
        uint256 umiInterest = calculateUmiTokenRewards(msg.sender);
        // update stakeDate of user
        stakeDates[msg.sender] = balances[msg.sender] > 0 ?  _now() : 0;

        uint256 nftBalance = nftBalances[msg.sender][_nftAddress][_id];
        require(
            nftBalance >= _value,
            "insufficient balance for unstake"
        );

        // reduce nft balance
        nftBalances[msg.sender][_nftAddress][_id] = nftBalance.sub(_value);
        // reduce total nft amount
        totalNftStaked = totalNftStaked.sub(_value);
        if (nftBalances[msg.sender][_nftAddress][_id] == 0) {
            // if balance of the nft id is 0, remove nft id and set flag=false
            removeUserNftId(_nftAddress, _id);
        }

        // transfer nft token from this contract
        getERC1155(_nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _id,
            _value,
            _data
        );
        // Transfer umiToken interest to user
        transferUmiInterest(msg.sender, umiInterest);
        // send event
        emit NftUnstaked(msg.sender, _nftAddress, _id, _value, _now());
    }

    /**
     * Batch unstake nft token from this contract.
     *
     * Note: It calls another internal "_batchUnstakeNfts" method. See its description.
     *       Reverts if ids and values length mismatch.
     *
     * @param nftAddress The address of nft contract.
     * @param ids The nft id array to be staked.
     * @param values The nft amount array.
     */
    function batchUnstakeNfts(
        address nftAddress,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external whenNotPaused nonReentrant {
        require(
            ids.length == values.length,
            "ids and values length mismatch"
        );
        _batchUnstakeNfts(address(this), msg.sender, nftAddress, ids, values, data);
    }

    /**
     * Batch unstake nft token from this contract.
     *
     * Note: when nft unstaked, apy will changed, should recalculate balance.
     * update nft balance, nft id and totalNftStaked.
     *
     * @param _from The address of sender.
     * @param _to The address of receiver.
     * @param _nftAddress The address of nft contract.
     * @param _ids The nft id array to be unstaked.
     * @param _values The nft amount array.
     */
    function _batchUnstakeNfts(
        address _from,
        address _to,
        address _nftAddress,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) internal {
        // calculate rewards of umi token
        uint256 umiInterest = calculateUmiTokenRewards(_from);
        // update stakeDate of user
        stakeDates[_from] = balances[_from] > 0 ?  _now() : 0;

        // update data
        for (uint256 i = 0; i < _ids.length; i++) {
            // get nft id
            uint256 id = _ids[i];
            // get amount of nft id
            uint256 value = _values[i];

            uint256 nftBalance = nftBalances[msg.sender][_nftAddress][id];
            require(
                nftBalance >= value,
                "insufficient nft balance for unstake"
            );
            nftBalances[msg.sender][_nftAddress][id] = nftBalance.sub(value);
            totalNftStaked = totalNftStaked.sub(value);
            if (nftBalances[msg.sender][_nftAddress][id] == 0) {
                // if balance of the nft id is 0, remove nft id and set flag=false
                removeUserNftId(_nftAddress, id);
            }
        }

        // transfer nft token from this contract
        getERC1155(_nftAddress).safeBatchTransferFrom(_from, _to, _ids, _values, _data);
        // Transfer umiToken interest to user
        transferUmiInterest(msg.sender, umiInterest);
        // send event
        emit NftsBatchUnstaked(msg.sender, _nftAddress, _ids, _values, _now());
    }

    /**
    * Withdraws the interest only of user, and updates the stake date, balance and etc..
    */
    function claim() external whenNotPaused nonReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "balance should more than 0");
        // calculate total balance with interest
        (uint256 totalWithInterest, uint256 principalOfRepresentUmi, uint256 timePassed) = calculateRewardsAndTimePassed(msg.sender, 0);
        require(
            totalWithInterest > 0 && timePassed >= 0,
            "calculate rewards and TimePassed error"
        );
        // interest to be paid
        uint256 interest = totalWithInterest.sub(principalOfRepresentUmi);
        require(interest > 0, "claim interest must more than 0");
        require(totalFunding >= interest, "total funding not enough to pay interest");
        // enough to pay interest
        // reduce total funding
        totalFunding = totalFunding.sub(interest);
        uint256 claimTimestamp = _now();
        // update stake date
        stakeDates[msg.sender] = claimTimestamp;
        // transfer interest to user
        require(
            umiToken.transfer(msg.sender, interest),
            "claim: transfer failed"
        );
        // send claim event
        emit Claimed(msg.sender, balance, interest, claimTimestamp);
    }

    /**
     * Calculate user's umiToken rewards.
     *
     * @param _from User address.
     */
    function calculateUmiTokenRewards(address _from) public view returns(uint256) {
        // if lpToken balance>0, pass time > 1 seconds, should calculate rewards of umiToken.
        // get current lp token balance
        uint256 balance = balances[_from];
        if (balance <= 0) {
            // stake first time, balance is 0, donot need to calculate rewards.
            return 0;
        }
        // calculate total balance with interest
        (uint256 totalWithInterest, uint principalOfRepresentUmi, uint256 timePassed) =
            calculateRewardsAndTimePassed(_from, 0);
        require(
            totalWithInterest > 0 && timePassed >= 0,
            "calculate rewards and TimePassed error"
        );
        // return rewards amount
        return totalWithInterest.sub(principalOfRepresentUmi);
    }

    /**
     * Calculate interest and time passed.
     *
     * @param _user User's address.
     * @param _amount Amount based on which interest is calculated. When 0, current stake balance is used.
     * @return Return total with interest and time passed.
     */
    function calculateRewardsAndTimePassed(address _user, uint256 _amount)
        internal
        view
        returns (uint256, uint256, uint256)
    {
        // current amount of lp token staked in contract
        uint256 currentBalance = balances[_user];
        uint256 amount = _amount == 0 ? currentBalance : _amount;
        uint256 stakeDate = stakeDates[_user];
        // seconds
        uint256 timePassed = _now().sub(stakeDate);
        if (timePassed < 1 seconds) {
            // if timePassed less than one second, rewards will be 0
            return (0, 0, timePassed);
        }
        // get total apy of user
        uint256 totalApy = getTotalApyOfUser(_user);
        // get lp token total supply
        uint256 lpTokenTotalSupply = lpToken.totalSupply();
        (uint112 umiReserve,,) = lpToken.getReserves();
        uint256 principalOfRepresentUmi = Calculator.getValueOfRepresentUmi(amount, lpTokenTotalSupply, umiReserve);
        uint256 totalWithInterest =
            Calculator.calculator(principalOfRepresentUmi, timePassed, totalApy);
        return (totalWithInterest, principalOfRepresentUmi, timePassed);
    }

    /**
     * Get umi token balance by address.
     * @param addr The address of the account that needs to check the balance.
     * @return Return balance of umi token.
     */
    function getUmiBalance(address addr) public view returns (uint256) {
        return umiToken.balanceOf(addr);
    }
    
    /**
     * Get erc1155 token instance by address.
     */
    function getERC1155(address _nftAddress) internal pure returns(IERC1155) {
       IERC1155 nftContract = IERC1155(_nftAddress);
       return nftContract;
    }

    /**
     * Get lp token balance by address.
     * @param addr The address of the account that needs to check the balance
     * @return Return balance of lp token.
     */
    function getLpBalance(address addr) public view returns (uint256) {
        return lpToken.balanceOf(addr);
    }

    /**
     * Get nft balance by user address and nft id.
     *
     * @param user The address of user.
     * @param nftAddress The address of nft contract.
     * @param id The nft id.
     */
    function getNftBalance(address user, address nftAddress, uint256 id)
        public
        view
        returns (uint256)
    {
        return getERC1155(nftAddress).balanceOf(user, id);
    }

    /**
     * Get user's nft ids array.
     * @param user The address of user.
     * @param nftAddress The address of nft contract.
     */
    function getUserNftIds(address user, address nftAddress)
        public
        view
        returns (uint256[] memory)
    {
        return userNftIds[user][nftAddress].ids;
    }

    /**
     * Get length of user's nft id array.
     * @param user The address of user.
     * @param nftAddress The address of nft contract.
     */
    function getUserNftIdsLength(address user, address nftAddress) public view returns (uint256) {
        return userNftIds[user][nftAddress].ids.length;
    }

    /**
     * Check whether user have certain nft or not.
     * @param user The address of user.
     * @param nftAddress The address of nft contract.
     * @param nftId The nft id of user.
     */
    function isNftIdExist(address user, address nftAddress, uint256 nftId)
        public
        view
        returns (bool)
    {
        NftSet storage nftSet = userNftIds[user][nftAddress];
        mapping(uint256 => bool) storage isIn = nftSet.isIn;
        return isIn[nftId];
    }

    /**
     * Set user's nft id.
     *
     * Note: when nft id donot exist, the nft id will be added to ids array, and the idIn flag will be setted true;
     * otherwise do nothing.
     *
     * @param user The address of user.
     * @param nftAddress The address of nft contract.
     * @param nftId The nft id of user.
     */
    function setUserNftIds(address user, address nftAddress, uint256 nftId) internal {
        NftSet storage nftSet = userNftIds[user][nftAddress];
        uint256[] storage ids = nftSet.ids;
        mapping(uint256 => bool) storage isIn = nftSet.isIn;
        if (!isIn[nftId]) {
            ids.push(nftId);
            isIn[nftId] = true;
        }
    }

    /**
     * Remove nft id of user.
     *
     * Note: when user's nft id amount=0, remove it from nft ids array, and set flag=false
     * 
     * @param nftAddress The address of nft contract.
     * @param nftId The nft id of user.
     */
    function removeUserNftId(address nftAddress, uint256 nftId) internal {
        NftSet storage nftSet = userNftIds[msg.sender][nftAddress];
        uint256[] storage ids = nftSet.ids;
        mapping(uint256 => bool) storage isIn = nftSet.isIn;
        require(ids.length > 0, "remove user nft ids, ids length must > 0");

        // find nftId index
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == nftId) {
                ids[i] = ids[ids.length - 1];
                isIn[nftId] = false;
                ids.pop();
            }
        }
    }

    /**
     * Set apy of nft.
     *
     * Note: apy will be an integer value, 40 stands for 40%
     */
    function setApyByTokenId(address nftAddress, uint256 id, uint8 apy) public onlyOwner {
        require(nftAddress != address(0), "nft address incorrect");
        require(id > 0 && apy > 0, "nft and apy must > 0");
        if (!isNftSupported[nftAddress]) {
           // if nft address never been added
           nftAddresses.push(nftAddress);
           isNftSupported[nftAddress] = true;
        }
        nftApys[nftAddress][id] = apy;
        emit NftApySet(nftAddress, id, apy, msg.sender);
    }

    /**
     * Check if nft id is in whitelist.
     * @param id The nft id.
     */
    function isInWhitelist(address nftAddress, uint256 id) public view returns(bool) {
        return nftApys[nftAddress][id] > 0;
    }

    /**
     * Get user's total apy.
     *
     * Note: when umi token staked, base apy will be 12%; otherwise total apy will be 0.
     *
     * @param user The address of user.
     */
    function getTotalApyOfUser(address user) public view returns (uint256) {
        uint256 balanceOfUmi = balances[user];
        // if umi balance=0, the apy will be 0
        if (balanceOfUmi <= 0) {
            return 0;
        }
        // totalApy
        uint256 totalApy = BASE_APY;
        
        for (uint256 i = 0; i< nftAddresses.length; i++) {
            uint256[] memory nftIds = getUserNftIds(user, nftAddresses[i]);
            if (nftIds.length <= 0) {
                continue;
            }
            // iter nftIds and calculate total apy
            for (uint256 j = 0; j < nftIds.length; j++) {
                uint256 nftId = nftIds[j];
                // get user balance of nft
                uint256 balance = nftBalances[user][nftAddresses[i]][nftId];
                // get apy of certain nft id
                uint256 apy = nftApys[nftAddresses[i]][nftId];
                totalApy = totalApy.add(balance.mul(apy));
            }
        }
        
        return totalApy;
    }

    /**
     * @return Returns current timestamp.
     */
    function _now() internal view returns (uint256) {
        // Note that the timestamp can have a 900-second error:
        // https://github.com/ethereum/wiki/blob/c02254611f218f43cbb07517ca8e5d00fd6d6d75/Block-Protocol-2.0.md
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
     * Pauses all token stake, unstake.
     *
     * See {Pausable-_pause}.
     *
     * Requirements: the caller must be the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * Unpauses all token stake, unstake.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements: the caller must be the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * Init apys when deploy contract.
     */
    function initApys() internal onlyOwner {
        // first nft contract
        // category 1(total 1)
        nftApys[firstNft][59] = 1;
        // category 2(total 3)
        nftApys[firstNft][18] = 2;
        nftApys[firstNft][19] = 2;
        nftApys[firstNft][20] = 2;
        // category 3(total 27)
        nftApys[firstNft][1] = 10;
        nftApys[firstNft][2] = 10;
        nftApys[firstNft][4] = 10;
        nftApys[firstNft][5] = 10;
        nftApys[firstNft][6] = 10;
        nftApys[firstNft][7] = 10;
        nftApys[firstNft][8] = 10;
        nftApys[firstNft][9] = 10;
        nftApys[firstNft][12] = 10;
        nftApys[firstNft][13] = 10;
        nftApys[firstNft][14] = 10;
        nftApys[firstNft][15] = 10;
        nftApys[firstNft][16] = 10;
        nftApys[firstNft][22] = 10;
        nftApys[firstNft][23] = 10;
        nftApys[firstNft][24] = 10;
        nftApys[firstNft][26] = 10;
        nftApys[firstNft][27] = 10;
        nftApys[firstNft][28] = 10;
        nftApys[firstNft][29] = 10;
        nftApys[firstNft][30] = 10;
        nftApys[firstNft][31] = 10;
        nftApys[firstNft][32] = 10;
        nftApys[firstNft][33] = 10;
        nftApys[firstNft][35] = 10;
        nftApys[firstNft][36] = 10;
        nftApys[firstNft][37] = 10;
        // category 4(total 4)
        nftApys[firstNft][3] = 20;
        nftApys[firstNft][11] = 20;
        nftApys[firstNft][25] = 20;
        nftApys[firstNft][34] = 20;
        // category 5(total 1)
        nftApys[firstNft][17] = 30;
        // category 6(total 7)
        nftApys[firstNft][38] = 40;
        nftApys[firstNft][39] = 40;
        nftApys[firstNft][40] = 40;
        nftApys[firstNft][41] = 40;
        nftApys[firstNft][42] = 40;
        nftApys[firstNft][43] = 40;
        nftApys[firstNft][44] = 40;

        nftApys[firstNft][52] = 40;
        nftApys[firstNft][60] = 40;
        nftApys[firstNft][61] = 40;
        nftApys[firstNft][62] = 40;
        nftApys[firstNft][63] = 40;
        nftApys[firstNft][64] = 40;
        nftApys[firstNft][65] = 40;
        nftApys[firstNft][66] = 40;
        nftApys[firstNft][67] = 40;
        // category 7(total 6)
        nftApys[firstNft][45] = 80;
        nftApys[firstNft][46] = 80;
        nftApys[firstNft][47] = 80;
        nftApys[firstNft][48] = 80;
        nftApys[firstNft][49] = 80;
        nftApys[firstNft][50] = 80;
        
        // second nft contract
        // category 4(total 1)
        nftApys[secondNft][1] = 20;
        // category 8(total 20)
        nftApys[secondNft][2] = 102;
        nftApys[secondNft][3] = 102;
        nftApys[secondNft][4] = 102;
        nftApys[secondNft][5] = 102;
        nftApys[secondNft][6] = 102;
        nftApys[secondNft][7] = 102;
        nftApys[secondNft][8] = 102;
        nftApys[secondNft][9] = 102;
        nftApys[secondNft][10] = 102;
        nftApys[secondNft][12] = 102;
        nftApys[secondNft][13] = 102;
        nftApys[secondNft][14] = 102;
        nftApys[secondNft][15] = 102;
        nftApys[secondNft][16] = 102;
        nftApys[secondNft][18] = 102;
        nftApys[secondNft][19] = 102;
        nftApys[secondNft][20] = 102;
        nftApys[secondNft][21] = 102;
        nftApys[secondNft][22] = 102;
        nftApys[secondNft][23] = 102;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "./CommonConstants.sol";

abstract contract ERC1155TokenReceiver is ERC1155Receiver, CommonConstants {

    /**
     * ERC1155Receiver hook for single transfer.
     * @dev Reverts if the caller is not the whitelisted NFT contract.
     */
    function onERC1155Received(
        address, /*operator*/
        address, /*from _msgSender*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        return ERC1155_ACCEPTED;
    }

    /**
     * ERC1155Receiver hook for batch transfer.
     * @dev Reverts if the caller is not the whitelisted NFT contract.
     */
    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*value*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        return ERC1155_BATCH_ACCEPTED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
    Note: Simple contract to use as base for const vals
*/
contract CommonConstants {

    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.3;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface ERC20Interface {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./abdk-libraries/ABDKMath64x64.sol";

/**
 * Tools for calculating rewards.
 * Calculation formula: F=P*(1+i)^n
 */
library Calculator {
    /*
     * calculate rewards
     * steps
     * 1. Calculate rewards by apy
     * 2. Get principal and rewards
     * @param principal principal amount
     * @param n periods for calculating interest,  one second eq to one period
     * @param apy annual percentage yield
     * @return sum of principal and rewards
     */
  function calculator(
        uint256 principal,
        uint256 n,
        uint256 apy
   ) internal pure returns (uint256 amount) {
        int128 div = ABDKMath64x64.divu(apy, 36500 * 1 days); // second rate
        int128 sum = ABDKMath64x64.add(ABDKMath64x64.fromInt(1), div);
        int128 pow = ABDKMath64x64.pow(sum, n);
        uint256 res = ABDKMath64x64.mulu(pow, principal);
        return res;
    }

  function getValueOfRepresentUmi(
      uint256 stakedLpTokens,
      uint256 lpTokenTotalSupply,
      uint112 umiReserve) internal pure returns(uint256) {
      int128 lpRatio = ABDKMath64x64.divu(stakedLpTokens, lpTokenTotalSupply);
      uint256 res = ABDKMath64x64.mulu(lpRatio, uint256(umiReserve));
      return res;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
interface IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}