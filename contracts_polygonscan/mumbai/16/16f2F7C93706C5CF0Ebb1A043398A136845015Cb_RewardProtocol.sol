/**
 *
 *  pay beats rewarding protocol
 *
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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
}

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

    constructor () {
        __Ownable_init();
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IRewardTracks {
    struct TrackMeta {
        uint256 id;
        bool isNftSpecific; // true when track is Nft specific
        address contractAddress; // nft contract address
        uint256 tokenId;    // is zero when it's Not Nft specific
        string name;
        string image;
        string description;
        string source;
        uint256 rewardsRate;
        uint256 trackDuration;
        bool isAdvertisement;
    }

    function addTrackToNftCard(
        address _nftContract,
        uint256 _tokenId,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _source,
        uint256 _rewards,
        uint256 _trackDuration,
        bool isAdvertisement
    ) external returns (uint256);

    function addTrackToNftsContract(
        address _nftContract,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _source,
        uint256 _rewards,
        uint256 _trackDuration,
        bool isAdvertisement
    ) external returns(uint256);

    function getSpecificNftTracks(
      address _nftContract,
      uint256 _tokenId
    )external view returns(TrackMeta[] memory);

    function getGenericContractTracks(
        address _nftContract
    ) external view returns(TrackMeta[] memory);

    function getAllTracks() external view returns(TrackMeta[] memory);
    
    function getTrackIdDuration(
      uint256 _trackId
    ) external
    view returns(uint256);

    function getTrackIdRewards(
      uint256 _trackId
    )external
    view returns(uint256);
}

/**
 * @dev Contract which provides control over user rewards based on their tracks playing
 * it works with two contracts (ERC20 <BEATS TOKEN CONTRACT>), and (RewardTracks)
 * this contract has all records for rewarding records for users.
 * this contract controls adding existing nfts for users ! 
 */
contract RewardProtocol is OwnableUpgradeable {
    using SafeMath for uint256;
    IERC20Metadata private immutable _erc20Contract;
    IRewardTracks private immutable _rewardTracks;

    /** start of rewards data structures */
    
    struct SummarizedAddressInfo {
        uint256 tokensCount;
        uint256 beatsAmount;
    }
    
    /** address => nft tokens count => beats amount */
    mapping(address => SummarizedAddressInfo) internal summarizedNftTable;
    /** nft contract address => nft token id => beats amount */
    mapping(address => mapping(uint256 => uint256)) internal detailedNftTable;
    /** user address => list of nft contract addresses */
    mapping(address => address[]) internal userNftContracts;
    /** contract address to minter address*/
    mapping(address => address) internal contractToMinter;

    mapping(address => bool) internal _isExcludedFromVesting;
    address[] private _excluded;

    struct VestingSchedule {
        bool initialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // sender of tokens
        address sender;
        // start time of the vesting period
        uint256 start;
        // end time of vesting period
        uint256 end;
        // duration of track
        uint256 duration;
        // token id
        uint256 tokenId;
        // track id
        uint256 trackId;
        // rewardRate
        uint256 rewardRate;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
    }

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    event ScheduleAdded(
        address indexed recipient,
        bytes32 vestingId,
        uint256 vestedAmount
    );
    event ScheduleTokensClaimed(
        address indexed recipient,
        uint256 amountClaimed
    );
    /** end of rewards data structures */

    /** constructor */
    /** here we add ERC20 contract address and Reward tracks contract address*/
    constructor(address erc20Contract_, address rewardTracksContract_) {
        require(erc20Contract_ != address(0x0));
        require(rewardTracksContract_ != address(0x0));
        _erc20Contract = IERC20Metadata(erc20Contract_);
        _rewardTracks = IRewardTracks(rewardTracksContract_);
        
        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));
    }

    /** start of rewards functions */

    /**
     * @dev Returns the number of vesting schedules associated to a beneficiary.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return holdersVestingCount[_beneficiary];
    }

    /**
     * @dev Returns the vesting schedule id at the given index.
     * @return the vesting id
     */
    function getVestingIdAtIndex(uint256 index)
        external
        view
        returns (bytes32)
    {
        require(
            index < getVestingSchedulesCount(),
            "TokenVesting: index out of bounds"
        );
        return vestingSchedulesIds[index];
    }

    /**
     * @notice Returns the vesting schedule information for a given holder and index.
     * @return the vesting schedule structure information
     */
    function getVestingScheduleByAddressAndIndex(address holder, uint256 index)
        external
        view
        returns (VestingSchedule memory)
    {
        return
            getVestingSchedule(
                computeVestingScheduleIdForAddressAndIndex(holder, index)
            );
    }

    /**
     * @notice Returns the total amount of vesting schedules.
     * @return the total amount of vesting schedules
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /** this function mints NFT contract! */
    function mintNftContract (
        address _nftContract,
        uint256 tokenId
    ) public {
        /** check if useraddress is owner of these tokens or not!! */
        //IERC721(_nftContract);

        /** set user as owner of this contract */
        userNftContracts[_msgSender()].push(_nftContract);
        //uint256 tokensCount = nftAddress2Count[_nftContract];
        summarizedNftTable[_nftContract].tokensCount = summarizedNftTable[_nftContract].tokensCount + 1;
        detailedNftTable[_nftContract][tokenId] = detailedNftTable[_nftContract][tokenId];
        contractToMinter[_nftContract] = _msgSender();
    }

    /** returns summary for nft contract address */
    function getSummarizedTable(
        address _nftContract
    ) public view returns(SummarizedAddressInfo memory){
        return summarizedNftTable[_nftContract];
    }

    /** returns details for nft contract address */
    function getDetailedTable(
        address _nftContract
    ) public view returns(uint256[] memory){
        uint count = summarizedNftTable[_nftContract].tokensCount;
        uint256[] memory ret = new uint256[](summarizedNftTable[_nftContract].tokensCount);
        uint Counter = 0;

        for (uint i=0; i<count; i++){
            ret[Counter] = detailedNftTable[_nftContract][i];
            Counter++;
        }
        /** return amount in tokenIds */
        return ret;
    }

    /** this function adds BEATS token to all cards in a contract */
    /** need to remove looping!! */
    function addBeatsToContract(
        address _nftContract,
        uint256 _beatsAmount
    ) public {
        require(
            _beatsAmount > 0,
            "amount should be positive"
        );

        uint256 tokensCount = summarizedNftTable[_nftContract].tokensCount;
        uint256 tokensPerCard = _beatsAmount.div(tokensCount);
        for (uint i = 0; i < tokensCount; i++) {
            detailedNftTable[_nftContract][i] = detailedNftTable[_nftContract][i] + tokensPerCard;
        }
        summarizedNftTable[_nftContract].beatsAmount = summarizedNftTable[_nftContract].beatsAmount + _beatsAmount;
    }

    /**
     * @notice in this function, a user can add BEATS value to token, so he can get money while listening
     * (this doesn't make sense till we make part of NFT price in MATIC transformed into BEATS tokens so user can claim them)
     * @param _tokenId nft token id 
     * @param _amount amount of beats tokens to add to NFT
     */
    function addBeatsToCard(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) public {
        //address _msgSender = _msgSender();
        require(
            _amount > 0,
            "amount should be positive"
        );
        summarizedNftTable[_nftContractAddress].beatsAmount = summarizedNftTable[_nftContractAddress].beatsAmount + _amount;
        detailedNftTable[_nftContractAddress][_tokenId]=detailedNftTable[_nftContractAddress][_tokenId] + _amount;
        _erc20Contract.transfer(owner(), _amount);
    }

    function _calculateVestableDuration(address _nftContract, uint256 _tokenId, uint256 _trackId)internal view returns(uint256){
        uint256 trackDuration = _rewardTracks.getTrackIdDuration(_trackId);
        uint256 trackRewardsRate = _rewardTracks.getTrackIdRewards(_trackId);
        uint256 totalReward = trackDuration.mul(trackRewardsRate);
        uint256 availableBeatsInNftForVesting = detailedNftTable[_nftContract][_tokenId];
        uint256 duration;

        if(availableBeatsInNftForVesting >= totalReward){
            return trackDuration;
        }else{
            duration = availableBeatsInNftForVesting.div(trackRewardsRate);
            return duration;
        }
    }

    function _calcualteVestableAmount(address _nftContract, uint256 _tokenId, uint256 _trackId)internal view returns(uint256){
        uint256 trackDuration = _rewardTracks.getTrackIdDuration(_trackId);
        uint256 trackRewardsRate = _rewardTracks.getTrackIdRewards(_trackId);
        uint256 totalReward = trackDuration.mul(trackRewardsRate);
        uint256 availableBeatsInNftForVesting = detailedNftTable[_nftContract][_tokenId];

        if(availableBeatsInNftForVesting >= totalReward){
            return totalReward;
        }else{
            return availableBeatsInNftForVesting;
        }
    }

    function _createVestingSchedule(
        address _beneficiary,
        address _msgSender,
        uint256 end,
        uint256 vestingDuration,
        uint256 _tokenId,
        uint256 _trackId,
        uint256 rewardsRate,
        uint256 vestingAmount
    )internal returns(bytes32){
        //address nftTokenAddress = address(_nftToken);
        //detailedNftTable[nftTokenAddress][_tokenId];
        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(
            _beneficiary
        );

        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            _msgSender,
            getCurrentTime(),
            end,
            vestingDuration * 1 seconds,
            _tokenId,
            _trackId,
            rewardsRate,
            vestingAmount,
            0
        );

        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(vestingAmount);
        vestingSchedulesIds.push(vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount.add(1);
        //detailedNftTable[nftTokenAddress][_tokenId] = detailedNftTable[nftTokenAddress][_tokenId].sub(vestingAmount);
        emit ScheduleAdded(_beneficiary, vestingScheduleId, vestingAmount);
        
        return vestingScheduleId;
    }

    /** get all vesting schedules for a NFT */
    function getNftVestingSchedules(uint256 tokenId) public view returns(VestingSchedule[] memory){
        uint256 systemVestingCount = this.getVestingSchedulesCount();
        VestingSchedule[] memory NftVestingSchedulesMeta = new VestingSchedule[](systemVestingCount);
        uint256 counter = 0;

        for (uint i = 0; i < systemVestingCount; i++) {
            bytes32 ScheduleId = vestingSchedulesIds[i];
            VestingSchedule memory loopVestingSchedule = this.getVestingSchedule(ScheduleId);

            if(loopVestingSchedule.tokenId == tokenId){
                NftVestingSchedulesMeta[counter] = loopVestingSchedule;
                counter++;
            }
        }
        return NftVestingSchedulesMeta;
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _tokenId amount
     * @param _trackId amount
     */
    function createVestingSchedule(
        address _beneficiary,
        address _nftContract,
        uint256 _tokenId,
        uint256 _trackId
    ) public returns (bytes32) {
        //IERC721(_nftContract);
        address _msgSender = _msgSender();
        require(
            _msgSender == owner() || _msgSender == _beneficiary,
            "TokenVesting: only owner or beneficiary can vest tokens"
        );
        require(
            _msgSender == owner() || contractToMinter[_nftContract] == _beneficiary,
            "You should own Beats NFT or you are the contract owner"
        );
        uint256 vestingDuration = _calculateVestableDuration(_nftContract, _tokenId, _trackId);
        uint256 vestingAmount   = _calcualteVestableAmount(_nftContract, _tokenId, _trackId);

        require(vestingAmount > 0 && vestingDuration > 0,
        "beneficiary doesn't have enough Beats");

        uint256 _trackRewardsRate = _rewardTracks.getTrackIdRewards(_trackId);
        uint256 vestingCountByBeneficiary = this.getVestingSchedulesCountByBeneficiary(_beneficiary);
        
        //uint256 _currentTime = getCurrentTime();
        if(vestingCountByBeneficiary == 0){
            // here if user doesn't have any vesting schedule => create a new one for him
            bytes32 VestingScheduleID = _createVestingSchedule(_beneficiary, _msgSender, 0, vestingDuration, _tokenId, _trackId, _trackRewardsRate, vestingAmount);
            //detailedNftTable[nftTokenAddress][_tokenId] = detailedNftTable[nftTokenAddress][_tokenId] - vestingAmount;
            return VestingScheduleID;
        }else{
            bytes32 currentVestingScheduleId = this.computeCurrentVestingScheduleIdForHolder(
                _beneficiary
            );

            VestingSchedule storage vestingSchedule = vestingSchedules[
                currentVestingScheduleId
            ];

            if(getCurrentTime() > vestingSchedule.start + vestingSchedule.duration){
                // here user finished his vesting => create a new record for him
                bytes32 newVestingScheduleID = _createVestingSchedule(_beneficiary, _msgSender, 0, vestingDuration, _tokenId, _trackId, _trackRewardsRate, vestingAmount);
                return newVestingScheduleID;
            }else{
                // user is currently vesting
                vestingSchedule.end = getCurrentTime();
                bytes32 newVestingScheduleId = _createVestingSchedule(_beneficiary, _msgSender, 0, vestingDuration, _tokenId, _trackId, _trackRewardsRate, vestingAmount);
                return newVestingScheduleId;
            }
        }
    }

    function getTokenBeats(address _nftContract, uint256 _tokenId)public view returns(uint256){
        return detailedNftTable[_nftContract][_tokenId];
    }

    /**
     * @notice Release vested amount of tokens.
     * @param vestingScheduleId the vesting schedule identifier
     * @param amount the amount to release
     */
    function release(bytes32 vestingScheduleId, uint256 amount)
        public
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
        
        //bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        
        //bool isOwner = msg.sender == owner();
        //require(
        //    isOwner || isBeneficiary,
        //    "TokenVesting: only owner or beneficiary can release vested tokens"
        //);
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(
            vestedAmount >= amount,
            "TokenVesting: cannot release tokens, not enough vested tokens"
        );

        vestingSchedule.released = vestingSchedule.released.add(amount);
        address payable beneficiaryPayable = payable(
            vestingSchedule.beneficiary
        );
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(
            vestingSchedule.amountTotal
        );

        detailedNftTable[vestingSchedule.beneficiary][vestingSchedule.tokenId] = detailedNftTable[vestingSchedule.beneficiary][vestingSchedule.tokenId].sub(amount);
        _erc20Contract.transfer(beneficiaryPayable, amount);
        emit ScheduleTokensClaimed(beneficiaryPayable, amount);
    }

    /**
     * @dev Returns the number of vesting schedules managed by this contract.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(bytes32 vestingScheduleId)
        public
        view
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(bytes32 vestingScheduleId)
        public
        view
        returns (VestingSchedule memory)
    {
        return vestingSchedules[vestingScheduleId];
    }

    /**
     * @dev Computes the next vesting schedule identifier for a given holder address.
     */
    function computeNextVestingScheduleIdForHolder(address holder)
        public
        view
        returns (bytes32)
    {
        return
            computeVestingScheduleIdForAddressAndIndex(
                holder,
                holdersVestingCount[holder]
            );
    }

    function getNftListeningValue(address beneficiary, uint256 tokenId) public view returns(uint256){
        return detailedNftTable[beneficiary][tokenId];
    }

    function _getNftListeningValue(address beneficiary, uint256 tokenId)
        internal
        view
    returns(uint256){
        return detailedNftTable[beneficiary][tokenId];
    }

    /**
     * @dev Computes the current vesting schedule identifier for a given holder address.
     */
    function computeCurrentVestingScheduleIdForHolder(address holder)
        public
        view
        returns (bytes32)
    {
        return
            computeVestingScheduleIdForAddressAndIndex(
                holder,
                holdersVestingCount[holder] - 1
            );
    }

    /**
     * @dev Returns the last vesting schedule for a given holder address.
     */
    function getLastVestingScheduleForHolder(address holder)
        public
        view
        returns (VestingSchedule memory)
    {
        return
            vestingSchedules[
                computeVestingScheduleIdForAddressAndIndex(
                    holder,
                    holdersVestingCount[holder] - 1
                )
            ];
    }

    /**
     * @dev Computes the vesting schedule identifier for an address and an index.
     */
    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = getCurrentTime();
        if (vestingSchedule.end == 0) {
            if(currentTime > vestingSchedule.start + vestingSchedule.duration){
                // here vesting is done, then we want to check how much user can release
                uint256 reward = vestingSchedule.amountTotal;
                return reward;
            } else {
                // here vesting is still running, then we want to check how much user can release 

                uint256 timeFromStart = currentTime.sub(vestingSchedule.start);
                uint256 vestedAmount = vestingSchedule.rewardRate.mul(
                    timeFromStart
                );

                vestedAmount = vestedAmount.sub(vestingSchedule.released);
                return vestedAmount;
            }
        } else {
            uint256 vestingTime = vestingSchedule.end - vestingSchedule.start;
            uint256 Rewards = vestingTime.mul(vestingSchedule.rewardRate);
            return Rewards;
        }
    }

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /** end of rewards functions   */

    function _exclude(address account) internal {
        _isExcludedFromVesting[account] = true;
        _excluded.push(account);
    }

    /** beginning of rewarding functionality */

    /** end of rewarding functionality */

}