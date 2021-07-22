/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PrismAdv {
    //
    IERC20 GOV;
    IERC20 IOU;
    
    // top candidates in "lazy decreasing" order by vote
    address[] public finalists;
    address[]                   public  elected;
    mapping (address => bool)   public  isFinalist;
    mapping (address=>bool)     public  isElected;
    uint256[]                   public  electedVotes;
    
    uint256 counter = 0;
    uint256 electedLength;
    uint256                     public  electedID;
    
    //
    mapping (address=>uint256)      public  votes;
    mapping (address=>uint256)      public  deposits;
    mapping (address=>uint256)      public  approvals;
    mapping (uint256=>address[])    public  slates;
    
    /**
    @notice Create a DSPrism instance.

    @param electionSize The number of candidates to elect.
    @param gov The address of the DSToken instance to use for governance.
    @param iou The address of the DSToken instance to use for IOUs.
    */
    constructor(IERC20 gov, IERC20 iou, uint electionSize) public
    {
        electedLength = electionSize;
        
        GOV = gov;
        IOU = iou;
    }
    
    /**
        @notice Swap candidates `i` and `j` in the vote-ordered list. This
        transaction will fail if `i` is greater than `j`, if candidate `i` has a
        higher score than candidate `j`, if the candidate one slot below the slot
        candidate `j` is moving to has more approvals than candidate `j`, or if
        candidate `j` has fewer than half the approvals of the most popular
        candidate.  This transaction will always succeed if candidate `j` has at
        least half the approvals of the most popular candidate and if candidate `i`
        either also has less than half the approvals of the most popular candidate
        or is `0x0`.
    
        @dev This function is meant to be called repeatedly until the list of
        candidates, `elected`, has been ordered in descending order by weighted
        approvals. The winning candidates will end up at the front of the list.
    
        @param i The index of the candidate in the `elected` list to move down.
        @param j The index of the candidate in the `elected` list to move up.
    */
    function swap(uint i, uint j) public {
        // 
        require(i < j, "error: invalid input");
        
        address a = finalists[i];
        address b = finalists[j];
        
        // swap 
        finalists[i] = b;
        finalists[j] = a;
    }
    
    /**
        @notice Replace candidate at index `i` in the set of elected candidates with
        the candidate at address `b`. This transaction will fail if candidate `i`
        has more approvals than the candidate at the given address, or if the
        candidate is already a finalist.
    
        @param i The index of the candidate to replace.
        @param b The address of the candidate to insert.
    */
    function drop(uint i, address b) public { 
        
        isFinalist[b] = true;
        
        address a = finalists[i];
        finalists[i] = b;
        isFinalist[a] = false;
        
    }
    
    /**
    @notice Elect the current set of finalists. The current set of finalists
    must be sorted or the transaction will fail.
    */
    function snap() public {
        // Either finalists[0] has the most approvals, or there will be someone
        // in the list out-of-order with more than half of finalists[0]'s
        // approvals.
        uint requiredApprovals = approvals[finalists[0]] / 2;

        for( uint i = 0; i < finalists.length - 1; i++ ) {
            isElected[elected[i]] = false;

            // All finalists with at least `requiredVotes` approvals are sorted.
            require(approvals[finalists[i+1]] <= approvals[finalists[i]] ||
                    approvals[finalists[i+1]] < requiredApprovals);

            if (approvals[finalists[i]] >= requiredApprovals) {
                electedVotes[i] = approvals[finalists[i]];
                elected[i] = finalists[i];
                isElected[elected[i]] = true;
            } else {
                elected[i] = address(0);
                electedVotes[i] = 0;
            }
        }
    }
    
    /**
        @notice Lock up `wad` wei voting tokens and increase your vote weight
        by the same amount.

        @param wad Number of tokens (in the token's smallest denomination) to lock.
    */
    function lock(uint wad) public {
        GOV.burn(msg.sender, wad);
        IOU.mint(msg.sender, wad);
        
        addWeight(wad, slates[votes[msg.sender]]);
        deposits[msg.sender] = deposits[msg.sender] + wad;
    }

    /**
        @notice Retrieve `wad` wei of your locked voting tokens and decrease your
        vote weight by the same amount.

        @param wad Number of tokens (in the token's smallest denomination) to free.
    */
    function free(uint wad) public {
        subWeight(wad, slates[votes[msg.sender]]);
        deposits[msg.sender] = deposits[msg.sender] - wad;
        
        GOV.mint(msg.sender, wad);
        IOU.burn(msg.sender, wad);
    }
    
    /**
        @notice Save an ordered addresses set and return a unique identifier for it.
    */
    function etch(address[] memory guys) public returns (uint256) {
        counter=counter+1;
        
        slates[counter] = guys;
        
        return counter;
    }
    
    /**
        @notice Vote for candidates `guys`. This transaction will fail if the set of
        candidates is not ordered according the their numerical values or if it
        contains duplicates. Returns a unique ID for the set of candidates chosen.
    
        @param guys The ordered set of candidate addresses to vote for.
    */
    function vote(address[] memory guys) public returns (uint256) {
        uint256 slate = etch(guys);
        
        vote(slate);

        return slate;
    }
    
    /**
    @notice Vote for the set of candidates with ID `which`.

    @param which An identifier returned by "etch" or "vote."
    */
    function vote(uint256 which) public {
        uint256 weight = deposits[msg.sender];
        subWeight(weight, slates[votes[msg.sender]]);
        addWeight(weight, slates[which]);
        votes[msg.sender] = which;
    }
    
    // Remove weight from slate.
    function subWeight(uint weight, address[] memory slate) internal {
        for( uint i = 0; i < slate.length; i++) {
            approvals[slate[i]] = approvals[slate[i]] - weight;
        }
    }

    // Add weight to slate.
    function addWeight(uint weight, address[] memory slate) internal {
        for( uint i = 0; i < slate.length; i++) {
            approvals[slate[i]] = approvals[slate[i]] - weight;
        }
    }
    
}