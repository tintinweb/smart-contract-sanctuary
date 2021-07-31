pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";

contract PolkaDex is ERC20 {
    
    uint256 blockTimeStamp;
    
    address payable owner;
    
    bool private IDO;
    
    mapping(address => bool) team;
    uint256 teamMemberCounter;
    
    mapping(address => string) investors;
    uint256 investorsSeedMemberCounter;
    uint256 investorsStrategicMemberCounter;
    uint256 investorsPrivateMemberCounter;
    
    mapping(address => bool) advisors;
    uint256 advisorsMemberCounter;
    
    mapping(address => bool) partnerships;
    uint256 partnershipsMemberCounter;
    
    
    uint256 teamTotalTokens = 1800000;
    uint256 seedStageTotalTokens = 1400000;
    uint256 strategicStageTotalTokens = 1600000;
    uint256 privateStageTotalTokens = 2200000;
    uint256 treasuryTotalTokens = 8200000;
    uint256 parachainAuctionTotalTokens = 2000000;
    uint256 advisorsTotalTokens = 1200000;
    uint256 partnershipsTotalTokens = 1200000;
    uint256 communityTotalTokens = 400000;
   
   
    
    address constant AhmetAddress = 0x40db0AA5a81fF051b73533a76A0B62a114D1f8b2;
    
    constructor() ERC20("Polkadex", "PDEX", 20000000) {
        blockTimeStamp = block.timestamp;
        owner = _msgSender();
        addMember("team", owner);
        //addMember("team", AhmetAddress);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized access");
        _;
    }
    
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
     function contains(address _address) private view returns (uint256){
        if(team[_address] == true) {
            return 1;
        } else if (advisors[_address] == true) {
            return 2;
        } else if (partnerships[_address] == true) {
            return 3;
        } else if (compareStrings(investors[_address], "seed") || compareStrings(investors[_address], "strategic") || compareStrings(investors[_address], "private")) {
            return 4;
        } 
        return 0;
    }
    
    function startIDO() public onlyOwner{
        IDO = true;
    } 
    
    function addMember(string memory group, address memberAddress) public onlyOwner returns (bool) {
        require(memberAddress != address(0));
        
        if(compareStrings(group, "team")) {
            
            if(contains(memberAddress) != 1) {
                team[memberAddress] = true;
                teamMemberCounter += 1;
                return true;
            }
            
        } else if (compareStrings(group, "advisors")) {
            
            if(contains(memberAddress) != 2) {
                advisors[memberAddress] = true;
                advisorsMemberCounter += 1;
                return true;
            }
            
        } else if (compareStrings(group, "partnerships")) {
            
            if(contains(memberAddress) != 3) {
                partnerships[memberAddress] = true;
                partnershipsMemberCounter += 1;
                return true;
            }
            
        } else if (compareStrings(group, "investors")) {
            
            if(contains(memberAddress) != 4) {
                if (block.timestamp > blockTimeStamp + 16 weeks) {
                    investors[memberAddress] = "seed";
                    investorsSeedMemberCounter += 1;
                    return true;
                } else if (block.timestamp > blockTimeStamp + 32 weeks) {
                    investors[memberAddress] = "strategic";
                    investorsStrategicMemberCounter += 1;
                    return true;
                } else if (block.timestamp > blockTimeStamp + 48 weeks) {
                    investors[memberAddress] = "private";
                    investorsPrivateMemberCounter += 1;
                    return true;
                }
            }
            
        }
        return false;
    }
    
    function deleteMember(string memory group, address memberAddress) public onlyOwner returns (bool) {
         require(memberAddress != address(0));
         
         if(compareStrings(group, "team")) {
             
             if(contains(memberAddress) == 1) {
                _burn(memberAddress, balanceOf(memberAddress));
                teamMemberCounter -= 1;
                return true; 
            }
            
         } else if(compareStrings(group, "advisors")) {
             
             if(contains(memberAddress) == 1) {
                _burn(memberAddress, balanceOf(memberAddress));
                advisorsMemberCounter -= 1;
                return true; 
            }
            
         } else  if(compareStrings(group, "partnerships")) {
             
             if(contains(memberAddress) == 1) {
                _burn(memberAddress, balanceOf(memberAddress));
                partnershipsMemberCounter -= 1;
                return true; 
            }
            
         } else if (compareStrings(group, "investors")) {
             
             if(contains(memberAddress) != 4) {
                if (block.timestamp > blockTimeStamp + 16 weeks) {
                    investors[memberAddress] = "seed";
                    investorsSeedMemberCounter += 1;
                    return true;
                } else if (block.timestamp > blockTimeStamp + 32 weeks) {
                    investors[memberAddress] = "strategic";
                    investorsStrategicMemberCounter += 1;
                    return true;
                } else if (block.timestamp > blockTimeStamp + 48 weeks) {
                    investors[memberAddress] = "private";
                    investorsPrivateMemberCounter += 1;
                    return true;
                }
            }
            
        }
        return false;
    }
    
    function getLaunchTokens(uint256 totalTokensForRoles, uint256 percentageLaunchTokens) pure private returns(uint256){
        uint256 launchTokens = totalTokensForRoles * percentageLaunchTokens / 100;
        
        totalTokensForRoles -= launchTokens;
        
        return launchTokens;
    }
    
    function getMyFirstSlice() public {
        require(_msgSender() != address(0), "ERC20: Not valid address");
        require(_balances[_msgSender()] == 0, "ERC20: You have received your initial tokens");
        
        uint256 launchTokens;
        uint256 slice;
        
        if (team[_msgSender()] == true) {
            launchTokens = getLaunchTokens(teamTotalTokens, 20);
            slice = launchTokens/teamMemberCounter;
            
            require(teamTotalTokens > slice, "ERC20: teamTotalTokens < slice");
            
            teamTotalTokens -= slice;
            _balances[_msgSender()] += slice;
            
            emit Transfer(address(0), _msgSender(), slice);
        } else if (advisors[_msgSender()] == true) {
            
            require(block.timestamp > blockTimeStamp + 24 weeks, "Time to claim advisors launch tokens has not reached");
            
            launchTokens = getLaunchTokens(advisorsTotalTokens, 12);
            slice = launchTokens/advisorsMemberCounter;
            
            require(advisorsTotalTokens > slice, "ERC20: advisorsTotalTokens < slice");
            
            advisorsTotalTokens -= slice;
            _balances[_msgSender()] += slice;
            
            emit Transfer(address(0), _msgSender(), slice);
        } else if (partnerships[_msgSender()] == true) {
            
            launchTokens = getLaunchTokens(partnershipsTotalTokens, 20);
            slice = launchTokens/partnershipsMemberCounter;
            
            require(partnershipsTotalTokens > slice, "ERC20: partnershipsTotalTokens < slice");
            
            partnershipsTotalTokens -= slice;
            _balances[_msgSender()] += slice;
            
            emit Transfer(address(0), _msgSender(), slice);
        } else if (compareStrings(investors[_msgSender()], "seed")) {
            launchTokens = getLaunchTokens(seedStageTotalTokens, 20);
            slice = launchTokens/investorsSeedMemberCounter;
            
            require(seedStageTotalTokens > slice, "ERC20: seedStageTotalTokens < slice");
            
            seedStageTotalTokens -= slice;
            _balances[_msgSender()] += slice;
            
            emit Transfer(address(0), _msgSender(), slice);
        } else if (compareStrings(investors[_msgSender()], "strategic")) {
            launchTokens = getLaunchTokens(strategicStageTotalTokens, 24);
            slice = launchTokens/investorsStrategicMemberCounter;
            
            require(strategicStageTotalTokens > slice, "ERC20: strategicStageTotalTokens < slice");
            
            strategicStageTotalTokens -= slice;
            _balances[_msgSender()] += slice;
            
            emit Transfer(address(0), _msgSender(), slice);
        } else if (compareStrings(investors[_msgSender()], "private")) {
            launchTokens = getLaunchTokens(privateStageTotalTokens, 28);
            slice = launchTokens/investorsPrivateMemberCounter;
            
            require(privateStageTotalTokens > slice, "ERC20: privateStageTotalTokens < slice");
            
            privateStageTotalTokens -= slice;
            _balances[_msgSender()] += slice;
            
            emit Transfer(address(0), _msgSender(), slice);
        }
    
    }
    
    function getCommunityTokens() public {
        require(_msgSender() != address(0), "ERC20: Not valid address");
        require(IDO == true, "ERC20: IDO not started yet");
        
        uint256 totalUsersCounter = teamMemberCounter + investorsSeedMemberCounter + investorsStrategicMemberCounter +
        investorsPrivateMemberCounter + advisorsMemberCounter + partnershipsMemberCounter;
        uint256 slice = communityTotalTokens/totalUsersCounter;
            
        require(communityTotalTokens > slice, "ERC20: communityTotalTokenss < slice");
            
        communityTotalTokens -= slice;
        _balances[_msgSender()] += slice;
            
        emit Transfer(address(0), _msgSender(), slice);
    }
    
    function calcQuarterlySlice(uint256 quarterlySlice, uint256 launchTokens, uint256 membersCount, uint256 usersTotalTokens) private{
        quarterlySlice = launchTokens;
        uint256 quarterlySliceForEveryMember = quarterlySlice/membersCount;
            
        usersTotalTokens -= quarterlySliceForEveryMember;
        _balances[_msgSender()] += quarterlySliceForEveryMember;
    }
    
    function getMyQuarterlySlice() public {
        require(_msgSender() != address(0));
        //require(block.timestamp > blockTimeStamp + 12 weeks, "Time to claim quarterly slice has not reached");
        
        uint256 quarterlySliceTeam;
        
        if(block.timestamp > blockTimeStamp + 12 weeks && block.timestamp < blockTimeStamp + 24 weeks) {
            if(team[_msgSender()] == true) {
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(teamTotalTokens, 20), teamMemberCounter, teamTotalTokens);
            } else if (advisors[_msgSender()] == true) {
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(advisorsTotalTokens, 22), advisorsMemberCounter, advisorsTotalTokens);
            } else if (partnerships[_msgSender()] == true) {
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(partnershipsTotalTokens, 20), partnershipsMemberCounter, partnershipsTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "seed")) {
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(seedStageTotalTokens, 20), investorsSeedMemberCounter, seedStageTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "strategic")) {
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(strategicStageTotalTokens, 19), investorsStrategicMemberCounter, strategicStageTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "private")) {
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(privateStageTotalTokens, 18), investorsPrivateMemberCounter, privateStageTotalTokens);
            }
        }
        
        if(block.timestamp > blockTimeStamp + 24 weeks && block.timestamp > blockTimeStamp + 36 weeks) {
            if(team[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(teamTotalTokens, 20), teamMemberCounter, teamTotalTokens);
            } else if (advisors[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(advisorsTotalTokens, 22), advisorsMemberCounter, advisorsTotalTokens);
            } else if (partnerships[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(partnershipsTotalTokens, 20), partnershipsMemberCounter, partnershipsTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "seed")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(seedStageTotalTokens, 20), investorsSeedMemberCounter, seedStageTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "strategic")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(strategicStageTotalTokens, 19), investorsStrategicMemberCounter, strategicStageTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "private")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(privateStageTotalTokens, 18), investorsPrivateMemberCounter, privateStageTotalTokens);
            }
        }
        
        if(block.timestamp > blockTimeStamp + 36 weeks && block.timestamp > blockTimeStamp + 48 weeks) {
            if(team[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(teamTotalTokens, 20), teamMemberCounter, teamTotalTokens);
            } else if (advisors[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(advisorsTotalTokens, 22), advisorsMemberCounter, advisorsTotalTokens);
            } else if (partnerships[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(partnershipsTotalTokens, 20), partnershipsMemberCounter, partnershipsTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "seed")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(seedStageTotalTokens, 20), investorsSeedMemberCounter, seedStageTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "strategic")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(strategicStageTotalTokens, 19), investorsStrategicMemberCounter, strategicStageTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "private")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(privateStageTotalTokens, 18), investorsPrivateMemberCounter, privateStageTotalTokens);
            }
        }
        
        if(block.timestamp > blockTimeStamp + 48 weeks) {
            if(team[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(teamTotalTokens, 20), teamMemberCounter, teamTotalTokens);
            } else if (advisors[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(advisorsTotalTokens, 22), advisorsMemberCounter, advisorsTotalTokens);
            } else if (partnerships[_msgSender()] == true) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(partnershipsTotalTokens, 20), partnershipsMemberCounter, partnershipsTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "seed")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(seedStageTotalTokens, 20), investorsSeedMemberCounter, seedStageTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "strategic")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(strategicStageTotalTokens, 19), investorsStrategicMemberCounter, strategicStageTotalTokens);
            } else if (compareStrings(investors[_msgSender()], "private")) {
                _totalSupply -= quarterlySliceTeam;
                calcQuarterlySlice(quarterlySliceTeam, getLaunchTokens(privateStageTotalTokens, 18), investorsPrivateMemberCounter, privateStageTotalTokens);
            }
        }
    }
    
}