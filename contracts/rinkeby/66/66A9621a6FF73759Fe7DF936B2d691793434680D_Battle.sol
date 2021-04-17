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

    mapping(address => uint) public balanceNDRPerUser;
    mapping(address => uint) public balanceNFTPerUser;

    mapping(address => uint) public totalNFTStrengthPerUser;
    mapping(address => uint) public pureNFTStrengthPerUser;
    mapping(address => bool) private percentMultiplierApplied;
    mapping(address => uint) public percentMultiplierPerUser;

    mapping(address => uint) public lastCheckTimePerUser;
    mapping(uint => uint) public lastCheckTimePerTeam;

    // mapping(uint => NftToken) public nftTokenMap;
    mapping(address => NftToken[]) public nftTokenMap;
    mapping(address => uint[]) public nftTokens;

    uint public battleDuration = 7 days;
    uint public rewardDuration = 24 hours;
    uint public startTime;

    address public owner;
    // bool public started;

    event NDRStaked(address indexed user, uint amount);
    event NFTStaked(address indexed user, uint tokenId, uint amount);
    event BoughtNFT(address indexed user, uint tokenId);
    event Withdrawn(address indexed user, uint tokenId, uint amount);

    constructor (
        address _NDR, address _NFT
        ) public {
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
        // uint teamStrength = totalNFTStrengthPerTeam[teamId];
        // uint teamNDRAmount = totalNDRAmountPerTeam[teamId];
        // if (teamStrength != 0) {
        //     if (teamNDRAmount > teamStrength) {
        //         dayHashPerTeam[teamId] = teamStrength;
        //     }
        //     dayHashPerTeam[teamId] = teamNDRAmount;
        // }
        uint rewardRateTeam = dayHashPerTeam[teamId] / rewardDuration;
        uint rewardRateUser = dayHashPerUser[msg.sender] / rewardDuration;
        totalHashPerTeam[teamId] += rewardRateTeam * (block.timestamp - lastCheckTimePerTeam[teamId]);
        totalHashPerUser[msg.sender] += rewardRateUser * (block.timestamp - lastCheckTimePerTeam[teamId]);
        lastCheckTimePerTeam[teamId] = block.timestamp;
        lastCheckTimePerUser[msg.sender] = block.timestamp;
        _;
    }

    function changeAddresses(address _NDR, address _NFT) public onlyOwner {
        NDR = IERC20(_NDR);
        NFT = IERC1155(_NFT);
    }

    function getTeamNDRAmount(uint teamId) public view returns (uint) {
        return totalNDRAmountPerTeam[teamId];
    }

    // function getNftTokens()

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    } 

    function selectTeam(uint teamId) public {
        require(teamIdPerUser[msg.sender] == 0, "Can not change team.");
        teamIdPerUser[msg.sender] = teamId;
    }

    function startBattle() public onlyOwner {
        startTime = block.timestamp;
    }

    function stakeNFT(uint[] calldata tokenIds, uint[] calldata amounts) public updateHash {
        require(startTime < block.timestamp, "The battle has not been started yet.");
        require(block.timestamp < startTime + battleDuration, "The battle has already been ended.");
        require(tokenIds.length == amounts.length, "TokenIds and amounts length should be the same");
        require(teamIdPerUser[msg.sender] > 0, "Please select team before staking");
        uint teamId = teamIdPerUser[msg.sender];
        for (uint i = 0; i < tokenIds.length; i++) {
            // stakeInternal
            stakeInternal(tokenIds[i], amounts[i]);
        }
    }

    function stakeInternal(uint256 tokenId, uint256 amount) internal {
        (uint256 strength,,,,,uint256 series) = INodeRunnersNFT(address(NFT)).getFighter(tokenId);
        strength = strength * amount;
        uint teamId = teamIdPerUser[msg.sender];

        // if(!nftTokenMap[tokenId].hasValue) {
        //     nftTokens.push(tokenId);
        //     nftTokenMap[tokenId] = NftToken({ hasValue: true });
        // }
        
        // uint totalStrength = totalNFTStrengthPerUser[msg.sender];
        // uint percentMultiplier = percentMultiplierPerUser[msg.sender];
        if (series == 3) {
            require(amount == 1, "only one nft with series 3 badge");
            require(percentMultiplierApplied[msg.sender] == false, "nft with series 3 already applied");
            percentMultiplierApplied[msg.sender] = true;
            // totalStrength = totalStrength * 11 / 10;
            // percentMultiplierPerUser[msg.sender] = percentMultiplierPerUser[msg.sender] * 110;
        }
        if (series == 4) {
            require(amount == 1, "only one nft with series 4 badge");
            // percentMultiplierPerUser[msg.sender] = percentMultiplierPerUser[msg.sender] * 105;
        }
        totalNFTStrengthPerTeam[teamId] = totalNFTStrengthPerTeam[teamId] - totalNFTStrengthPerUser[msg.sender];
        pureNFTStrengthPerUser[msg.sender] = pureNFTStrengthPerUser[msg.sender] + strength;

        if (percentMultiplierApplied[msg.sender]) {
            totalNFTStrengthPerUser[msg.sender] = pureNFTStrengthPerUser[msg.sender] * 110 / 100; 
        } else {
            totalNFTStrengthPerUser[msg.sender] = pureNFTStrengthPerUser[msg.sender];
        }

        // totalStrength += strength;
        balanceNFTPerUser[msg.sender] += amount;
        totalNFTStrengthPerTeam[teamId] += totalNFTStrengthPerUser[msg.sender];
        // totalNFTStrengthPerUser[msg.sender] = totalStrength;
        nftTokenMap[msg.sender].push(NftToken(tokenId, amount));
        // nftTokenMap[tokenId].balances[msg.sender] += amount;

        NFT.safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x0");
        updateDayHash(msg.sender, teamId);
        // totalHashPerTeam[teamId] = totalNDRAmountPerTeam[teamId] * 
        emit NFTStaked(msg.sender, tokenId, amount);

    }

    function stakeNDR(uint256 amount) public updateHash {
        require(startTime < block.timestamp, "The battle has not been started yet.");
        require(block.timestamp < startTime + battleDuration, "The battle has already been ended.");
        require(amount > 0, "Cannot stake 0");
        require(teamIdPerUser[msg.sender] > 0, "Please select team before staking");
        uint256 teamId = teamIdPerUser[msg.sender];
        uint256 teamNDRAmount = totalNDRAmountPerTeam[teamId];
        uint256 userNDRAmount = balanceNDRPerUser[msg.sender];
        // TODO get teamHash
        NDR.transferFrom(msg.sender, address(this), amount);
        teamNDRAmount += amount;
        userNDRAmount += amount;
        totalNDRAmountPerTeam[teamId] = teamNDRAmount;
        balanceNDRPerUser[msg.sender] = userNDRAmount;
        updateDayHash(msg.sender, teamId);
        // uint teamStrength = totalNFTStrengthPerTeam[teamId];
        // uint userStrength = totalNFTStrengthPerUser[msg.sender];
        // if (teamStrength != 0) {
        //     if (teamNDRAmount > teamStrength) {
        //         dayHashPerTeam[teamId] = teamStrength;
        //         dayHashPerUser[msg.sender] = userStrength;
        //     } else {
        //         dayHashPerTeam[teamId] = teamNDRAmount;
        //         dayHashPerUser[msg.sender] = userNDRAmount;
        //     }
        // }

        // lastCheckTimePerUser[msg.sender] = block.timestamp;
        // lastCheckTimePerTeam[teamId] = block.timestamp;

        emit NDRStaked(msg.sender, amount);
    }

    function updateDayHash(address user, uint teamId) internal {
        uint teamStrength = totalNFTStrengthPerTeam[teamId];
        uint userStrength = totalNFTStrengthPerUser[user];
        uint teamNDRAmount = totalNDRAmountPerTeam[teamId];
        uint userNDRAmount = balanceNDRPerUser[user];
        if (teamStrength != 0) {
            if (teamNDRAmount > teamStrength) {
                dayHashPerTeam[teamId] = teamStrength;
                dayHashPerUser[user] = userStrength;
            } else {
                dayHashPerTeam[teamId] = teamNDRAmount;
                dayHashPerUser[user] = userNDRAmount;
            }
        }
    }

    function buyNewNFT(uint tokenId) public updateHash {
        (,,,,uint256 hashPrice,) = INodeRunnersNFT(address(NFT)).getFighter(tokenId);
        require(hashPrice > 0, "can't buy in hash");
        uint teamId = teamIdPerUser[msg.sender];
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

    function withdraw() public {
        require(block.timestamp > startTime + battleDuration, "The battle has not been ended");
        // uint length = nftTokenMap[msg.sender].length;
        NftToken[] memory tokens = nftTokenMap[msg.sender];
        for (uint i = 0; i< tokens.length; i++) {
            uint id = tokens[i].tokenId;
            uint amount = tokens[i].balances;
            NFT.safeTransferFrom(address(this), msg.sender, id, amount, "0x0");
            emit Withdrawn(msg.sender, id, amount);
        }

        uint ndrAmount = balanceNDRPerUser[msg.sender];
        balanceNDRPerUser[msg.sender] -= ndrAmount;
        NDR.transfer(msg.sender, ndrAmount);

        // ndr send, validate balance
    }

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