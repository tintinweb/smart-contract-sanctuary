// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";

contract uSTD is ERC20Burnable, Ownable {
    /*
    $uSTD backed by the presidents 
*/

    using SafeMath for uint256;

    uint256 public MAX_WALLET_STAKED = 10;
    uint256 public EMISSIONS_RATE = 11574070000000;
    uint256 public CLAIM_END_TIME = 1641013200;

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public washieAddress;   // tokenid's 1 - 10,000
    address public abeAddress;      // tokenid's 10001 - 15000
    address public hamiltonAddress; // tokenid's 15001 - 17500
    address public jacksonAddress;  // tokenid's 17501 - 19000
    address public grantAddress;    // tokenid's 19001 - 19750
    address public bennyAddress;    // tokenid's 19751 - 20000
    
    //Mapping of president to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    //Mapping of president to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    //Mapping of staker to president
    mapping(address => uint256[]) internal stakerToTokenIds;

    constructor() ERC20("Unstables", "uSTD") {}

    function setWashieAddress(address _washieAddress) public onlyOwner {
        washieAddress = _washieAddress;
        return;
    }
    
    function setAbeAddress(address _abeAddress) public onlyOwner {
        abeAddress = _abeAddress;
        return;
    }

    function setHamiltonAddress(address _hamiltonAddress) public onlyOwner {
        hamiltonAddress = _hamiltonAddress;
        return;
    }
    
    function setJacksonAddress(address _jacksonAddress) public onlyOwner {
        jacksonAddress = _jacksonAddress;
        return;
    }
    
    function setGrantAddress(address _grantAddress) public onlyOwner {
        grantAddress = _grantAddress;
        return;
    }
    
    function setBennyAddress(address _bennyAddress) public onlyOwner {
        bennyAddress = _bennyAddress;
        return;
    }
    
    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(
            stakerToTokenIds[msg.sender].length + tokenIds.length <=
                MAX_WALLET_STAKED,
            "Must have less than 31 presidents staked!"
        );
        
        address prez;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] <= 10000) {
                prez = washieAddress ;
            } else if (tokenIds[i] > 10000 && tokenIds[i] <= 15000) {
                prez = abeAddress;
            } else if (tokenIds[i] > 15000 && tokenIds[i] <= 17500) {
                prez = hamiltonAddress;
            } else if (tokenIds[i] > 17500 && tokenIds[i] <= 18000) {
                prez = jacksonAddress;
            } else if (tokenIds[i] > 18000 && tokenIds[i] <= 19000) {
                prez = grantAddress;
            } else if (tokenIds[i] > 19000 && tokenIds[i] <= 20000) {
                prez = bennyAddress;
            }
            
            require(
                    IERC721(prez).ownerOf(tokenIds[i]) == msg.sender 
                    &&
                        tokenIdToStaker[tokenIds[i]] == nullAddress,
                    "Token must be stakable by you!"
                );
    
            IERC721(prez).transferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i]
                );
            
            

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one token staked!"
        );
        uint256 totalRewards = 0;
        
        uint256 presidentEmissions = 0;
        
        address prez;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];
            
            if (tokenId <= 10000) {
                prez = washieAddress;
                presidentEmissions = EMISSIONS_RATE;
            } else if (tokenId > 10000 && tokenId <= 15000) {
                prez = abeAddress;
                presidentEmissions = EMISSIONS_RATE * 5;
            } else if (tokenId > 15000 && tokenId <= 17500) {
                prez = hamiltonAddress;
                presidentEmissions = EMISSIONS_RATE * 10;
            } else if (tokenId > 17500 && tokenId <= 18000) {
                prez = jacksonAddress;
                presidentEmissions = EMISSIONS_RATE * 20;
            } else if (tokenId > 18000 && tokenId <= 19000) {
                prez = grantAddress;
                presidentEmissions = EMISSIONS_RATE * 50;
            } else if (tokenId > 19000 && tokenId <= 20000) {
                prez = bennyAddress;
                presidentEmissions = EMISSIONS_RATE * 100;
            }

            IERC721(prez).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    presidentEmissions);

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;
            
            _mint(msg.sender, totalRewards);
        }

        
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;
        
        uint256 presidentEmissions = 0;
        
        address prez;

        for (uint256 i = 0; i < tokenIds.length; i++) {
           
            if (tokenIds[i] <= 10000) {
                prez = washieAddress;
                presidentEmissions = EMISSIONS_RATE;
            } else if (tokenIds[i] > 10000 && tokenIds[i] <= 15000) {
                prez = abeAddress;
                presidentEmissions = EMISSIONS_RATE * 5;
            } else if (tokenIds[i] > 15000 && tokenIds[i] <= 17500) {
                prez = hamiltonAddress;
                presidentEmissions = EMISSIONS_RATE * 10;
            } else if (tokenIds[i] > 17500 && tokenIds[i] <= 18000) {
                prez = jacksonAddress;
                presidentEmissions = EMISSIONS_RATE * 20;
            } else if (tokenIds[i] > 18000 && tokenIds[i] <= 19000) {
                prez = grantAddress;
                presidentEmissions = EMISSIONS_RATE * 50;
            } else if (tokenIds[i] > 19000 && tokenIds[i] <= 20000) {
                prez = bennyAddress;
                presidentEmissions = EMISSIONS_RATE * 100;
            }
            
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(prez).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    presidentEmissions);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;
            
            _mint(msg.sender, totalRewards);
        }

        
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        
        uint256 presidentEmissions = 0;
        
        if (tokenId <= 10000) {
                presidentEmissions = EMISSIONS_RATE;
            } else if (tokenId > 10000 && tokenId <= 15000) {
                presidentEmissions = EMISSIONS_RATE * 5;
            } else if (tokenId > 15000 && tokenId <= 17500) {
                presidentEmissions = EMISSIONS_RATE * 10;
            } else if (tokenId > 17500 && tokenId <= 18000) {
                presidentEmissions = EMISSIONS_RATE * 20;
            } else if (tokenId > 18000 && tokenId <= 19000) {
                presidentEmissions = EMISSIONS_RATE * 50;
            } else if (tokenId > 19000 && tokenId <= 20000) {
                presidentEmissions = EMISSIONS_RATE * 100;
            }

        _mint(
            msg.sender,
            ((block.timestamp - tokenIdToTimeStamp[tokenId]) * presidentEmissions)
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimAll() public {
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;
        uint256 presidentEmissions = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );
            
            if (tokenIds[i] <= 10000) {
                presidentEmissions = EMISSIONS_RATE;
            } else if (tokenIds[i] > 10000 && tokenIds[i] <= 15000) {
                presidentEmissions = EMISSIONS_RATE * 5;
            } else if (tokenIds[i] > 15000 && tokenIds[i] <= 17500) {
                presidentEmissions = EMISSIONS_RATE * 10;
            } else if (tokenIds[i] > 17500 && tokenIds[i] <= 18000) {
                presidentEmissions = EMISSIONS_RATE * 20;
            } else if (tokenIds[i] > 18000 && tokenIds[i] <= 19000) {
                presidentEmissions = EMISSIONS_RATE * 50;
            } else if (tokenIds[i] > 19000 && tokenIds[i] <= 20000) {
                presidentEmissions = EMISSIONS_RATE * 100;
            }

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    presidentEmissions);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;
        uint256 presidentEmissions = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            
            if (tokenIds[i] <= 10000) {
                presidentEmissions = EMISSIONS_RATE;
            } else if (tokenIds[i] > 10000 && tokenIds[i] <= 15000) {
                presidentEmissions = EMISSIONS_RATE * 5;
            } else if (tokenIds[i] > 15000 && tokenIds[i] <= 17500) {
                presidentEmissions = EMISSIONS_RATE * 10;
            } else if (tokenIds[i] > 17500 && tokenIds[i] <= 18000) {
                presidentEmissions = EMISSIONS_RATE * 20;
            } else if (tokenIds[i] > 18000 && tokenIds[i] <= 19000) {
                presidentEmissions = EMISSIONS_RATE * 50;
            } else if (tokenIds[i] > 19000 && tokenIds[i] <= 20000) {
                presidentEmissions = EMISSIONS_RATE * 100;
            }
            
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    presidentEmissions);
        }

        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != nullAddress,
            "Token is not staked!"
        );
        
        uint256 presidentRewards = 0;
        
        if (tokenId <= 10000) {
                presidentRewards = EMISSIONS_RATE;
            } else if (tokenId > 10000 && tokenId <= 15000) {
                presidentRewards = EMISSIONS_RATE * 5;
            } else if (tokenId > 15000 && tokenId <= 17500) {
                presidentRewards = EMISSIONS_RATE * 10;
            } else if (tokenId > 17500 && tokenId <= 18000) {
                presidentRewards = EMISSIONS_RATE * 20;
            } else if (tokenId > 18000 && tokenId <= 19000) {
                presidentRewards = EMISSIONS_RATE * 50;
            } else if (tokenId > 19000 && tokenId <= 20000) {
                presidentRewards = EMISSIONS_RATE * 100;
            }

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];

        return secondsStaked * presidentRewards;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }
}