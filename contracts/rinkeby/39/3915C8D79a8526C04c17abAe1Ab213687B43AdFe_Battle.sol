// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface INodeRunnersNFT {
    function getFighter(uint256 tokenId) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function mint(address to, uint256 id, uint256 amount) external;
}

contract Battle {
    IERC20 public NDR;
    IERC1155 public NFT;

    // struct NftToken {
    //     bool hasValue;
    //     mapping(address => uint) balances;
    // }

    struct NftToken {
        uint tokenId;
        uint balances;
    }

    mapping(address => uint) public teamIdPerUser;
    mapping(uint => uint) public totalNDRAmountPerTeam;
    mapping(uint => uint) public totalNFTStrengthPerTeam;

    mapping(uint => uint) public totalHashPerTeam;
    mapping(address => uint) public totalHashPerUser;

    mapping(uint => uint) public dayHashPerTeam;
    mapping(address => uint) public dayHashPerUser;

    // mapping(address => uint) public balanceNFTPerUser;

    mapping(address => uint) public totalNFTStrengthPerUser;
    mapping(address => uint) public totalNDRAmountPerUser;

    mapping(address => uint) public pureNFTStrengthPerUser;
    mapping(address => uint) private percentMultiplierApplied;
    mapping(address => uint) public percentMultiplierPerUser;

    mapping(address => uint) public lastCheckTimePerUser;
    mapping(uint => uint) public lastCheckTimePerTeam;

    // mapping(uint => NftToken) public nftTokenMap;
    mapping(address => NftToken[]) public nftTokenMap;
    mapping(address => uint[]) public nftTokens;

    mapping(uint => mapping(uint => bool)) public acceptableIdTeam;
    mapping(uint => uint) public playersCounter;

    // default: 7 days
    uint private battleDuration = 7 days;

    uint public rewardDuration = 24 hours;
    uint public startTime;
    uint private _nftFee;

    address public owner;
    // bool public started;

    event NDRStaked(address indexed user, uint amount);
    event NFTStaked(address indexed user, uint tokenId, uint amount);
    event BoughtNFT(address indexed user, uint tokenId);
    event WithdrawnNFT(address indexed user, uint tokenId, uint amount);
    event WithdrawnNDR(address indexed user, uint amount);

    constructor (
        address _NDR, address _NFT
        ) {
        NDR = IERC20(_NDR);
        NFT = IERC1155(_NFT);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier updateHash() {
        uint teamId = teamIdPerUser[msg.sender];
        uint rewardRateTeam = dayHashPerTeam[teamId] / rewardDuration;
        uint rewardRateUser = dayHashPerUser[msg.sender] / rewardDuration;
        totalHashPerTeam[teamId] += rewardRateTeam * (block.timestamp - lastCheckTimePerTeam[teamId]);
        totalHashPerUser[msg.sender] += rewardRateUser * (block.timestamp - lastCheckTimePerUser[msg.sender]);
        lastCheckTimePerTeam[teamId] = block.timestamp;
        lastCheckTimePerUser[msg.sender] = block.timestamp;
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setSupportedIds(uint[] calldata tokenIds, uint teamId) public onlyOwner {
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            acceptableIdTeam[teamId][tokenId] = true;
        }
    }

    function setBattleDuration(uint _duration) public onlyOwner {
        require(startTime == 0, "Can not change during the battle");
        require(_duration > 0, "Invalid duration value");

        battleDuration = _duration;
    }

    function getBattleDuration() public view returns (uint) {
        return battleDuration;
    }

    function changeAddresses(address _NDR, address _NFT) public onlyOwner {
        NDR = IERC20(_NDR);
        NFT = IERC1155(_NFT);
    }

    function getTeamNDRAmount(uint teamId) public view returns (uint) {
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        return totalNDRAmountPerTeam[teamId];
    }

    function getTeamTotalNFTStrength(uint teamId) public view returns (uint) {
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        return totalNFTStrengthPerTeam[teamId];
    }

    function getUserTotalNFTStrength(address user) public view returns (uint) {
        return totalNFTStrengthPerUser[user];
    }

    function getTeamDayHash(uint teamId) public view returns (uint) {
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        return dayHashPerTeam[teamId];
    }

    function getUserDayHash(address user) public view returns (uint) {
        return dayHashPerUser[user];
    }

    function selectTeam(uint teamId) public {
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        require(teamIdPerUser[msg.sender] == 0, "Can not change team.");
        teamIdPerUser[msg.sender] = teamId;
        playersCounter[teamId] += 1;
    }

    function startBattle() public onlyOwner {
        require(startTime == 0, "already started!");
        startTime = block.timestamp;
    }

    function battleFinishDate() public view returns (uint) {
        require(block.timestamp >= startTime, "The battle has not been started.");
        require(block.timestamp < startTime + battleDuration, "The battle has already been ended.");
        return startTime + battleDuration;
    }

    function getTeamHashResult(uint teamId) public view returns (uint) {
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        require(block.timestamp >= startTime, "The battle has not been started.");
        uint rewardRateTeam = dayHashPerTeam[teamId] / rewardDuration;
        uint lastTotalHash = totalHashPerTeam[teamId];
        if (block.timestamp >= startTime + battleDuration) {
            lastTotalHash += rewardRateTeam * (startTime + battleDuration - lastCheckTimePerTeam[teamId]);
        } else {
            lastTotalHash += rewardRateTeam * (block.timestamp - lastCheckTimePerTeam[teamId]);
        }
        return lastTotalHash;
    }

    function getUserHashResult(address user) public view returns (uint) {
        // require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        require(block.timestamp >= startTime, "The battle has not been started.");
        uint rewardRateUser = dayHashPerUser[user] / rewardDuration;
        uint lastTotalHash = totalHashPerUser[user];
        if (block.timestamp >= startTime + battleDuration) {
            lastTotalHash += rewardRateUser * (startTime + battleDuration - lastCheckTimePerUser[user]);
        } else {
            lastTotalHash += rewardRateUser * (block.timestamp - lastCheckTimePerUser[user]);
        }
        return lastTotalHash;
    }

    function stakeNFT(uint[] calldata tokenIds, uint[] calldata amounts) public payable updateHash {
        require(startTime < block.timestamp, "The battle has not been started yet.");
        require(block.timestamp < startTime + battleDuration, "The battle has already been ended.");
        require(tokenIds.length == amounts.length, "TokenIds and amounts length should be the same");
        require(teamIdPerUser[msg.sender] > 0, "Please select team before staking");
        for (uint i = 0; i < tokenIds.length; i++) {
            // stakeInternal
            stakeInternal(tokenIds[i], amounts[i]);
        }
    }

    function stakeInternal(uint256 tokenId, uint256 amount) internal {
        uint teamId = teamIdPerUser[msg.sender];
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        require(acceptableIdTeam[teamId][tokenId] == true, "Not acceptable tokenId for this team.");
        (uint256 strength,,,,,uint256 series) = INodeRunnersNFT(address(NFT)).getFighter(tokenId);
        strength = strength * amount * 100;

        if (series == 3) {
            require(amount == 1, "only one nft with series 3 badge");
            require(percentMultiplierApplied[msg.sender] == 0 || percentMultiplierApplied[msg.sender] == 2, "nft with series 3 already applied");
            if (percentMultiplierApplied[msg.sender] == 0) {
                percentMultiplierApplied[msg.sender] = 1;
            } else {
                percentMultiplierApplied[msg.sender] == 3;
            }
        }
        if (series == 4) {
            require(amount == 1, "only one nft with series 4 badge");
            require(percentMultiplierApplied[msg.sender] == 0 || percentMultiplierApplied[msg.sender] == 1, "nft with series 4 already applied");
            if (percentMultiplierApplied[msg.sender] == 0) {
                percentMultiplierApplied[msg.sender] = 2;
            } else {
                percentMultiplierApplied[msg.sender] = 3;
            }
        }
        totalNFTStrengthPerTeam[teamId] = totalNFTStrengthPerTeam[teamId] - totalNFTStrengthPerUser[msg.sender];
        pureNFTStrengthPerUser[msg.sender] = pureNFTStrengthPerUser[msg.sender] + strength;

        if (percentMultiplierApplied[msg.sender] == 1) {
            totalNFTStrengthPerUser[msg.sender] = pureNFTStrengthPerUser[msg.sender] * 110 / 100;
        } else if (percentMultiplierApplied[msg.sender] == 2) {
            totalNFTStrengthPerUser[msg.sender] = pureNFTStrengthPerUser[msg.sender] * 105 / 100;
        } else if (percentMultiplierApplied[msg.sender] == 3) {
            totalNFTStrengthPerUser[msg.sender] = pureNFTStrengthPerUser[msg.sender] * 11 * 105 / 1000;
        } else {
            totalNFTStrengthPerUser[msg.sender] = pureNFTStrengthPerUser[msg.sender];
        }

        // balanceNFTPerUser[msg.sender] += amount;
        totalNFTStrengthPerTeam[teamId] += totalNFTStrengthPerUser[msg.sender];
        nftTokenMap[msg.sender].push(NftToken(tokenId, amount));

        NFT.safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x0");
        updateDayHash(msg.sender, teamId);
        emit NFTStaked(msg.sender, tokenId, amount);
    }

    function stakeNDR(uint amount) public payable updateHash {
        require(startTime < block.timestamp, "The battle has not been started yet.");
        require(block.timestamp < startTime + battleDuration, "The battle has already been ended.");
        require(amount > 0, "Cannot stake 0");
        require(teamIdPerUser[msg.sender] > 0, "Please select team before staking");
        uint teamId = teamIdPerUser[msg.sender];
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        uint teamNDRAmount = totalNDRAmountPerTeam[teamId];
        uint userNDRAmount = totalNDRAmountPerUser[msg.sender];
        // TODO get teamHash
        NDR.transferFrom(msg.sender, address(this), amount);
        teamNDRAmount += amount;
        userNDRAmount += amount;
        totalNDRAmountPerTeam[teamId] = teamNDRAmount;
        totalNDRAmountPerUser[msg.sender] = userNDRAmount;
        updateDayHash(msg.sender, teamId);

        emit NDRStaked(msg.sender, amount);
    }

    function updateDayHash(address user, uint teamId) internal {
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        uint teamStrength = totalNFTStrengthPerTeam[teamId];
        uint userStrength = totalNFTStrengthPerUser[user];
        uint teamNDRAmount = totalNDRAmountPerTeam[teamId] / (1e18);
        // uint userNDRAmount = totalNDRAmountPerUser[user] / (1e18);
        if (teamStrength != 0) {
            if (teamNDRAmount * 10000 > teamStrength) {
                dayHashPerTeam[teamId] = teamStrength;
                dayHashPerUser[user] = userStrength;
            } else {
                dayHashPerTeam[teamId] = totalNDRAmountPerTeam[teamId];
                dayHashPerUser[user] = totalNDRAmountPerUser[user];
            }
        }
    }

    function setNftFee() external payable onlyOwner {
        _nftFee = msg.value;
    }

    function getNftFee() public view returns(uint) {
        require(_nftFee > 0, "Nft fee has not set yet.");
        return _nftFee;
    }

    function getMintingFee(uint rarity, uint teamId) internal view returns (uint) {
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        uint teamStrength = totalNFTStrengthPerTeam[teamId];
        uint teamNDRAmount = totalNDRAmountPerTeam[teamId] / (1e18);
        uint fee = rarity * teamNDRAmount * 10000 / teamStrength;
        return fee;
    }

    function buyNewNFT(uint tokenId) public updateHash payable {
        (,,,uint256 rarity,uint256 hashPrice,) = INodeRunnersNFT(address(NFT)).getFighter(tokenId);
        uint teamId = teamIdPerUser[msg.sender];
        require(teamId == 1 || teamId == 2, "teamId should be 1 or 2");
        require(hashPrice > 0, "can't buy in hash");
        uint fee = getMintingFee(rarity, teamId);
        require(msg.value >= fee, "wrong value");
        uint userHash = totalHashPerUser[msg.sender];
        uint teamHash = totalHashPerTeam[teamId];
        require(userHash >= hashPrice, "not enough Hash");
        userHash = userHash - hashPrice;
        teamHash = teamHash - hashPrice;
        totalHashPerUser[msg.sender] = userHash;
        totalHashPerTeam[teamId] = teamHash;
        INodeRunnersNFT(address(NFT)).mint(msg.sender, tokenId, 1);

        emit BoughtNFT(msg.sender, tokenId);
    }

    function withdrawNFT() public {
        require(block.timestamp > startTime + battleDuration, "The battle has not been ended");
        NftToken[] memory tokens = nftTokenMap[msg.sender];
        for (uint i = 0; i< tokens.length; i++) {
            uint id = tokens[i].tokenId;
            uint amount = tokens[i].balances;
            tokens[i].balances -= amount;
            NFT.safeTransferFrom(address(this), msg.sender, id, amount, "0x0");
            emit WithdrawnNFT(msg.sender, id, amount);
        }
        totalNFTStrengthPerUser[msg.sender] = 0;
    }

    function withdrawNDR() public {
        require(block.timestamp > startTime + battleDuration, "The battle has not been ended");
        uint ndrAmount = totalNDRAmountPerUser[msg.sender];
        totalNDRAmountPerUser[msg.sender] -= ndrAmount;
        NDR.transfer(msg.sender, ndrAmount);
        emit WithdrawnNDR(msg.sender, ndrAmount);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function seize(address to) external onlyOwner {
        uint amount = address(this).balance;
        payable(to).transfer(amount);
    }
}