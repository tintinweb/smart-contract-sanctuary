// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

interface ISilverHunter {
    function getPoint(uint16 id) external view returns(uint16);
    function ownerOf(uint id) external view returns (address);
    function isViking(uint16 id) external view returns (bool);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) external;
}

interface ISilver {
    function mint(address account, uint amount) external;
}

contract Castle is Ownable, IERC721Receiver {
    bool private _paused = false;

    uint16 private _randomIndex = 0;
    uint private _randomCalls = 0;
    mapping(uint => address) private _randomSource;

    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint16 tokenId, uint value);
    event KnightClaimed(uint16 tokenId, uint earned, bool unstaked);
    event VikingClaimed(uint16 tokenId, uint earned, bool unstaked);

    ISilverHunter public silverHunter;
    ISilver public silver;

    mapping(uint256 => uint256) public knightIndices;
    mapping(address => Stake[]) public knightStake;

    mapping(uint256 => uint256) public vikingIndices;
    mapping(address => Stake[]) public vikingStake;
    address[] public vikingHolders;

    // Total staked tokens
    uint public totalKnightStaked;
    uint public totalVikingStaked = 0;
    uint public unaccountedRewards = 0;

    // GoldMiner earn 10000 $SILVER per day
    uint public constant DAILY_SILVER_RATE = 10000 ether;
    uint public constant MINIMUM_TIME_TO_EXIT = 2 days;
    uint public constant TAX_PERCENTAGE = 20;
    uint public constant MAXIMUM_GLOBAL_SILVER = 2400000000 ether;

    uint public totalSilverEarned;

    uint public lastClaimTimestamp;
    // uint public vikingReward = 0;
    uint public vikingRewardPerPoint = 0;
    uint public totalPointStaked = 0;

    // emergency rescue to allow unstaking without any checks but without $SILVER
    bool public rescueEnabled = false;

    constructor() {
        // Fill random source addresses
        _randomSource[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _randomSource[1] = 0x3cD751E6b0078Be393132286c442345e5DC49699;
        _randomSource[2] = 0xb5d85CBf7cB3EE0D56b3bB207D5Fc4B82f43F511;
        _randomSource[3] = 0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94;
        _randomSource[4] = 0x28C6c06298d514Db089934071355E5743bf21d60;
        _randomSource[5] = 0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2;
        _randomSource[6] = 0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function setSilverHunter(address _silverHunter) external onlyOwner {
        silverHunter = ISilverHunter(_silverHunter);
    }

    function setSilver(address _silver) external onlyOwner {
        silver = ISilver(_silver);
    }

    function getAccountKnights(address user) external view returns (Stake[] memory) {
        return knightStake[user];
    }

    function getAccountVikings(address user) external view returns (Stake[] memory) {
        return vikingStake[user];
    }

    function addTokensToStake(address account, uint16[] calldata tokenIds) external {
        require(account == msg.sender || msg.sender == address(silverHunter), "You do not have a permission to do that");

        for (uint i = 0; i < tokenIds.length; i++) {
            if (msg.sender != address(silverHunter)) {
                // dont do this step if its a mint + stake
                require(silverHunter.ownerOf(tokenIds[i]) == msg.sender, "This NTF does not belong to address");
                silverHunter.transferFrom(msg.sender, address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (silverHunter.isViking(tokenIds[i])) {
                _stakeVikings(account, tokenIds[i]);
            } else {
                _stakeKnights(account, tokenIds[i]);
            }
        }
    }

    function _stakeKnights(address account, uint16 tokenId) internal whenNotPaused _updateEarnings {
        totalKnightStaked += 1;

        knightIndices[tokenId] = knightStake[account].length;
        knightStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        }));
        emit TokenStaked(account, tokenId, block.timestamp);
    }


    function _stakeVikings(address account, uint16 tokenId) internal {
        totalVikingStaked += 1;

        uint256 point = silverHunter.getPoint(tokenId);
        totalPointStaked += point;

        // If account already has some pirates no need to push it to the tracker
        if (vikingStake[account].length == 0) {
            vikingHolders.push(account);
        }

        vikingIndices[tokenId] = vikingStake[account].length;
        vikingStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(vikingRewardPerPoint)
            }));

        emit TokenStaked(account, tokenId, vikingRewardPerPoint);
    }


    function claimFromStake(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
        uint owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (!silverHunter.isViking(tokenIds[i])) {
                owed += _claimFromKnight(tokenIds[i], unstake);
            } else {
                owed += _claimFromViking(tokenIds[i], unstake);
            }
        }
        if (owed == 0) return;
        silver.mint(msg.sender, owed);
    }

    function _claimFromKnight(uint16 tokenId, bool unstake) internal returns (uint owed) {
        Stake memory stake = knightStake[msg.sender][knightIndices[tokenId]];
        require(stake.owner == msg.sender, "This NTF does not belong to address");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TIME_TO_EXIT), "Need to wait 2 days since last claim");

        if (totalSilverEarned < MAXIMUM_GLOBAL_SILVER) {
            owed = ((block.timestamp - stake.value) * DAILY_SILVER_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $SILVER production stopped already
        } else {
            owed = ((lastClaimTimestamp - stake.value) * DAILY_SILVER_RATE) / 1 days; // stop earning additional $SILVER if it's all been earned
        }
        if (unstake) {
            if (getSomeRandomNumber(tokenId, 100) <= 50) {
                _payTax(owed);
                owed = 0;
            }
            updateRandomIndex();
            totalKnightStaked -= 1;

            Stake memory lastStake = knightStake[msg.sender][knightStake[msg.sender].length - 1];
            knightStake[msg.sender][knightIndices[tokenId]] = lastStake;
            knightIndices[lastStake.tokenId] = knightIndices[tokenId];
            knightStake[msg.sender].pop();
            delete knightIndices[tokenId];

            silverHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            _payTax((owed * TAX_PERCENTAGE) / 100); // Pay some $SILVER to pirates!
            owed = (owed * (100 - TAX_PERCENTAGE)) / 100;
            
            uint80 timestamp = uint80(block.timestamp);

            knightStake[msg.sender][knightIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: timestamp
            }); // reset stake
        }

        emit KnightClaimed(tokenId, owed, unstake);
    }

    function _claimFromViking(uint16 tokenId, bool unstake) internal returns (uint owed) {
        require(silverHunter.ownerOf(tokenId) == address(this), "This NTF does not belong to address");

        Stake memory stake = vikingStake[msg.sender][vikingIndices[tokenId]];

        require(stake.owner == msg.sender, "This NTF does not belong to address");
        uint256 point = silverHunter.getPoint(tokenId);
        owed = (point) * (vikingRewardPerPoint - stake.value);

        if (unstake) {
            totalVikingStaked -= 1; // Remove Alpha from total staked
            totalPointStaked -= point;
            Stake memory lastStake = vikingStake[msg.sender][vikingStake[msg.sender].length - 1];
            vikingStake[msg.sender][vikingIndices[tokenId]] = lastStake;
            vikingIndices[lastStake.tokenId] = vikingIndices[tokenId];
            vikingStake[msg.sender].pop();
            delete vikingIndices[tokenId];
            updateVikingOwnerAddressList(msg.sender);

            silverHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            vikingStake[msg.sender][vikingIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: uint80(vikingRewardPerPoint)
            }); // reset stake
        }
        emit VikingClaimed(tokenId, owed, unstake);
    }

    function updateVikingOwnerAddressList(address account) internal {
        if (vikingStake[account].length != 0) {
            return; // No need to update holders
        }

        // Update the address list of holders, account unstaked all pirates
        address lastOwner = vikingHolders[vikingHolders.length - 1];
        uint indexOfHolder = 0;
        for (uint i = 0; i < vikingHolders.length; i++) {
            if (vikingHolders[i] == account) {
                indexOfHolder = i;
                break;
            }
        }
        vikingHolders[indexOfHolder] = lastOwner;
        vikingHolders.pop();
    }

    function rescue(uint16[] calldata tokenIds) external {
        require(rescueEnabled, "Rescue disabled");
        uint16 tokenId;
        Stake memory stake;

        for (uint16 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (!silverHunter.isViking(tokenId)) {
                stake = knightStake[msg.sender][knightIndices[tokenId]];

                require(stake.owner == msg.sender, "This NTF does not belong to address");

                totalKnightStaked -= 1;

                Stake memory lastStake = knightStake[msg.sender][knightStake[msg.sender].length - 1];
                knightStake[msg.sender][knightIndices[tokenId]] = lastStake;
                knightIndices[lastStake.tokenId] = knightIndices[tokenId];
                knightStake[msg.sender].pop();
                delete knightIndices[tokenId];

                silverHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");

                emit KnightClaimed(tokenId, 0, true);
            } else {
                stake = vikingStake[msg.sender][vikingIndices[tokenId]];
        
                require(stake.owner == msg.sender, "This NTF does not belong to address");

                totalVikingStaked -= 1;
                uint256 point = silverHunter.getPoint(tokenId);
                totalPointStaked -= point;
                    
                Stake memory lastStake = vikingStake[msg.sender][vikingStake[msg.sender].length - 1];
                vikingStake[msg.sender][vikingIndices[tokenId]] = lastStake;
                vikingIndices[lastStake.tokenId] = vikingIndices[tokenId];
                vikingStake[msg.sender].pop();
                delete vikingIndices[tokenId];
                updateVikingOwnerAddressList(msg.sender);
                
                silverHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");
                
                emit VikingClaimed(tokenId, 0, true);
            }
        }
    }

    function _payTax(uint _amount) internal {
        if (totalVikingStaked == 0) {
            unaccountedRewards += _amount;
            return;
        }

        vikingRewardPerPoint += (_amount + unaccountedRewards) / totalPointStaked;
        unaccountedRewards = 0;
    }


    modifier _updateEarnings() {
        if (totalSilverEarned < MAXIMUM_GLOBAL_SILVER) {
            totalSilverEarned += ((block.timestamp - lastClaimTimestamp) * totalKnightStaked * DAILY_SILVER_RATE) / 1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }


    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }


    function randomVikingOwner() external returns (address) {
        if (totalVikingStaked == 0) return address(0x0);

        uint holderIndex = getSomeRandomNumber(totalVikingStaked, vikingHolders.length);
        updateRandomIndex();

        return vikingHolders[holderIndex];
    }

    function updateRandomIndex() internal {
        _randomIndex += 1;
        _randomCalls += 1;
        if (_randomIndex > 6) _randomIndex = 0;
    }

    function getSomeRandomNumber(uint _seed, uint _limit) internal view returns (uint16) {
        uint extra = 0;
        for (uint16 i = 0; i < 7; i++) {
            extra += _randomSource[_randomIndex].balance;
        }

        uint random = uint(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    extra,
                    _randomCalls,
                    _randomIndex
                )
            )
        );

        return uint16(random % _limit);
    }

    function changeRandomSource(uint _id, address _address) external onlyOwner {
        _randomSource[_id] = _address;
    }

    function shuffleSeeds(uint _seed, uint _max) external onlyOwner {
        uint shuffleCount = getSomeRandomNumber(_seed, _max);
        _randomIndex = uint16(shuffleCount);
        for (uint i = 0; i < shuffleCount; i++) {
            updateRandomIndex();
        }
    }

    function onERC721Received(
        address,
        address from,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to this contact directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}