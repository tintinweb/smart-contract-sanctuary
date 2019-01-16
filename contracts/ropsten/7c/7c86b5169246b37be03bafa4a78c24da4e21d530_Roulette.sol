pragma solidity ^0.4.0;

contract Roulette {
    // Each bet profile will transfer to company_address
    // Player wining will transfer from company address to player address
    address company_address;
    
    // Bet type lookup
    uint[][] bet_lookup;
    
    // Player bet form
    struct Player {
        address wallet_address;
        uint[]  bet_types;
        uint[]  bet_amount;
    }
    
    // Payout table
    mapping(uint => uint) payout_table;
    
    // Initialize upon contract deploy (Setup bet type)
    constructor(address company) public {
        // Setup company wallet address
        company_address = company;
        
        // # Initialize game setting is commented due to unable to
        // # deploy contract & upload to ropsten (Seem is storage issue)
        // initBetType();
        // initPayoutTable();
    }
    
    // Players place bet
    // Input structure is one place bet will insert both bet_type and bet_amount
    // Eg: Player place a bet on Single number &#39;36&#39; & Red color both 0.01 ETH
    // <FOLLOW_BET_ID> && <BET AMOUNT>
    // b_type[0] = 36 && b_amount[0] = 0.01 ETH
    // b_type[1] = 41 && b_amount[1] = 0.01 ETH
    function bet(uint[] b_type, uint[] b_amount) payable public {
        // Ensure no missing data structure
        require(b_type.length != b_amount.length);
        
        // No empty bet amount && bet type
        require(b_type.length > 0 && b_amount.length > 0);
        
        address sender_address = msg.sender;
        
        Player memory p;
        p.wallet_address = sender_address;
        p.bet_types      = b_type;
        p.bet_amount     = b_amount;
        
        // Roll the ball to get a wining number
        uint result_number = getRandomResult();
        
        // Based on wining number check possible of combination of payout
        uint[] memory wining_list = getWiningType(result_number);
        uint win_amount           = 0;
        uint capital_amount       = 0;
        uint loss_amount          = 0;
        
        // Based on the wining_list (profitable bet type ids), compare with user bet type
        for(uint i = 0; i < p.bet_types.length; i++) {
            uint is_win = 0;
            
            for(uint j = 0; j < wining_list.length; j++) {
                // Win (user bet type matched with wining list)
                if(i == j) {
                    win_amount     += (p.bet_amount[0] * payout_table[i]);
                    capital_amount += p.bet_amount[0];
                    is_win = 1;
                }
                
                break;
            }
            
            // Lose
            if(is_win <= 0) {
                loss_amount += p.bet_amount[0];
            }
        }
        
        // Player gain
        if(win_amount + capital_amount> 0) {
            msg.sender.transfer(win_amount + capital_amount);
        }
        
        // Player loss (company profit)
        if(loss_amount > 0) {
            company_address.transfer(loss_amount);
        }
    }
    
    // Retrive wining number by RNG method
    function getRandomResult() private constant returns (uint) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty))%36);
    }
    
    // Retrieve possible of combination of wining payout
    function getWiningType(uint number) private constant returns (uint[]) {
        uint[] win_arr;

        // Based on each bet wining combination, check the wining number is inside the bet type
        // Bet lookup struture (array in array) : [
        //     <BET_TYPE>       => <NUMBER_INCLUDED>,
        //     1  (straight up) => [1], 
        //     41 (red color)   => [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36] 
        // ]
        
        for(uint i = 0; i < bet_lookup.length; i++) {
            for(uint j = 0; j < bet_lookup[i].length; j++) {
                if(number == j) {
                    win_arr.push(i);
                    break;
                }
            }
        }
        
        return win_arr;
    }
    
    function initPayoutTable() private {
        // straight up
        for(uint i = 1; i <= 36; i++) {
            payout_table[i] = 35;
        }
        
        // 1-18
        payout_table[37] = 1;
        // 19-36
        payout_table[38] = 1;
        
        // even
        payout_table[39] = 1;
        // odd
        payout_table[40] = 1;

        // red
        payout_table[41] = 1;
        // black
        payout_table[42] = 1;
        
        // Dozen (first12)
        payout_table[43] = 2;
        // Dozen (second12)
        payout_table[44] = 2;
        // Dozen (third12)
        payout_table[45] = 2;
        
        // Column (top)
        payout_table[46] = 2;
        // Column (middle)
        payout_table[47] = 2;
        // Column (lower)
        payout_table[48] = 2;
        
        // Split
        for(uint j = 49; j <= 105; j++) {
            payout_table[j] = 17;
        }
        
        // Corner
        for(uint k = 106; k <= 129; k++) {
            payout_table[k] = 8;
        }
        
        // street (130 - 141)
        for(uint l = 130; l <= 141; l++) {
            payout_table[l] = 11;
        }
        
        // double street (142 - 147)
        for(uint m = 142; m <= 147; m++) {
            payout_table[m] = 5;
        }
    }
    
    function initBetType() private {
        uint[] storage even_num;
        uint[] storage odd_num;
        uint[] storage one_to_oneEight;
        uint[] storage oneNine_to_threeSix;
        uint[] storage first_twelve;
        uint[] storage second_twelve;
        uint[] storage third_twelve;

        // Input single bet from (0 - 36)
        for(uint i = 0; i <= 36; i++) {
            bet_lookup.push([i]); 
            
            if(i % 2 != 0) {
                even_num.push(i);
            }else{
                odd_num.push(i);
            }
            
            if(i >= 1 && i <= 12) {
                first_twelve.push(i);
            }else if(i >= 13 && i <= 24){
                second_twelve.push(i);
            }else{
                third_twelve.push(i);
            }
        }

        // 1to18 (37)
        for(uint j = 0; j <= 18; j++) {
            one_to_oneEight.push(j);
        }
        bet_lookup.push(one_to_oneEight);
        
        // 19to36 (38)
        for(uint k = 0; k <= 18; k++) {
            oneNine_to_threeSix.push(k);
        }
        bet_lookup.push(oneNine_to_threeSix);
        
        // even number (39)
        bet_lookup.push(even_num);
        
        // odd_number (40)
        bet_lookup.push(odd_num);
        
        // red (41)
        bet_lookup.push([1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36]);
        
        // black (42)
        bet_lookup.push([2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33,35]);
        
        // first twelve (43)
        bet_lookup.push(first_twelve);
        
        // second twelve (44)
        bet_lookup.push(second_twelve);
        
        // third twelve (45)
        bet_lookup.push(third_twelve);
        
        // first column (46)
        bet_lookup.push([3,6,9,12,15,18,21,24,27,30,33,36]);
        
        // second column (47)
        bet_lookup.push([2,5,8,11,14,17,20,23,26,29,32,35]);
        
        // third column (48)
        bet_lookup.push([1,4,7,10,13,16,19,22,25,28,31,34]);
        
        // split - left right (first column) (49 - 59)
        for(uint l = 0; l < 12; i++) {
            if(l == 0) {
                bet_lookup.push([0, bet_lookup[46][l]]);
            }else{
                bet_lookup.push([bet_lookup[46][l - 1], bet_lookup[46][l]]);   
            }
        }
        
        // split - left right (second column) (60 - 70)
        for(uint m = 0; m < 12; m++) {
            if(m == 0) {
                bet_lookup.push([0, bet_lookup[47][m]]);
            }else {
                bet_lookup.push([bet_lookup[47][m - 1], bet_lookup[47][m]]);
            }
            
        }
        
        // split - left right (third column) (71 - 81)
        for(uint n = 0; n < 12; n++) {
            if(n == 0) {
                bet_lookup.push([0, bet_lookup[48][n]]);
            }else {
                bet_lookup.push([bet_lookup[48][n - 1], bet_lookup[48][n]]);
            }
        }
        
        // split - up down (top + middle) (82 - 93)
        bet_lookup.push([3,2]);
        bet_lookup.push([6,5]);
        bet_lookup.push([9,8]);
        bet_lookup.push([12,11]);
        bet_lookup.push([15,14]);
        bet_lookup.push([18,17]);
        bet_lookup.push([21,20]);
        bet_lookup.push([23,24]);
        bet_lookup.push([27,26]);
        bet_lookup.push([30,29]);
        bet_lookup.push([33,32]);
        bet_lookup.push([36,35]);
        
        // split - up down (middle + lower) (94 - 105)
        bet_lookup.push([1,2]);
        bet_lookup.push([4,5]);
        bet_lookup.push([7,8]);
        bet_lookup.push([10,11]);
        bet_lookup.push([13,14]);
        bet_lookup.push([16,17]);
        bet_lookup.push([19,20]);
        bet_lookup.push([23,22]);
        bet_lookup.push([25,26]);
        bet_lookup.push([28,29]);
        bet_lookup.push([31,32]);
        bet_lookup.push([34,35]);
        
        // corner (top + middle) (106 - 116)
        bet_lookup.push([3,6,2,5]);
        bet_lookup.push([6,9,5,8]);
        bet_lookup.push([9,8,12,11]);
        bet_lookup.push([14,15,12,11]);
        bet_lookup.push([15,14,18,17]);
        bet_lookup.push([18,17,21,20]);
        bet_lookup.push([21,20,24,23]);
        bet_lookup.push([24,23,27,26]);
        bet_lookup.push([27,26,30,29]);
        bet_lookup.push([30,29,33,32]);
        bet_lookup.push([33,32,36,35]);
        
        // corner (middle + lower) (117 - 127)
        bet_lookup.push([2,1,5,4]);
        bet_lookup.push([5,4,8,7]);
        bet_lookup.push([8,7,11,10]);
        bet_lookup.push([11,10,14,13]);
        bet_lookup.push([14,13,17,16]);
        bet_lookup.push([17,16,20,19]);
        bet_lookup.push([20,19,23,22]);
        bet_lookup.push([23,22,26,25]);
        bet_lookup.push([26,25,29,28]);
        bet_lookup.push([29,28,32,31]);
        bet_lookup.push([32,31,34,35]);
        
        // corner (zero + top middle) (128)
        bet_lookup.push([0,2,3]);
        
        // corner (zero + middle lower) (129)
        bet_lookup.push([0,1,2]);
        
        // street (130 - 141)
        for(uint o = 0; o <= 33; o+=3) {
            bet_lookup.push([o, o+1, o+2]); 
        }
        
        // double street (142 - 147)
        for(uint p = 0; p <= 33; p+=6) {
            bet_lookup.push([o, o+1, o+2, o+3, o+4, o+5]); 
        }
    }
}