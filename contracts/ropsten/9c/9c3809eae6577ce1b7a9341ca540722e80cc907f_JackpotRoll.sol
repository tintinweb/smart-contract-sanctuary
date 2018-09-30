pragma solidity ^0.4.24;

/*
Proudly created by JackpotRoll.com
*/

contract JackpotRoll {
    uint constant Game_Cut_Percentage = 1;
    uint constant Game_Modulo = 100;
    uint constant Jackpot_Small_Modulo = 100;
    uint constant Jackpot_Medium_Modulo = 1000;
    uint constant Jackpot_Large_Modulo = 10000;
    uint constant Jackpot_Ticket_Price = 0.003 ether; // 0.001 for each jackpot
    uint constant Min_Ticket_Price = 0.01 ether;
    uint constant Game_Expires_After = 250;
    address public Owner;
    address private Next_Owner;

    uint public Max_Profit;
    address public Secret_Signer_Address;
    uint128 public Jackpot_Small_Pool;
    uint128 public Jackpot_Medium_Pool;
    uint128 public Jackpot_Large_Pool;
    uint128 public Locked_in_Box;
  
    struct Game {
        uint Amount;
        uint8 Roll_Under;
        uint40 Played_Block_Number;
        address Gamer;
    }

    mapping (uint => Game) games;
    address public Croupier;

    event FailedPayment(address indexed Beneficiary, uint Amount);
    event Payment(address indexed Beneficiary, uint Amount);
    event JackpotPayment(address indexed Beneficiary, uint Amount, uint Jackpot_Type);
    event Commit_Log(uint Commit);
    
    constructor () public {
        Owner = msg.sender;
        Secret_Signer_Address = 0x3C2478326dcDDC41f59d7E730f09E818dBCDa8b9;
        Croupier = 0x3C2478326dcDDC41f59d7E730f09E818dBCDa8b9;
    }

    modifier onlyOwner {
        require (msg.sender == Owner, "onlyOwner funcs can only be called by Owner");
        _;
    }

    modifier onlyCroupier {
        require (msg.sender == Croupier, "onlyOwner funcs can only be called by Owner");
        _;
    }

     function approveNextOwner(address _Next_Owner) external onlyOwner {
        require (_Next_Owner != Owner, "Cannot approve current owner.");
        Next_Owner = _Next_Owner;
    }

    function acceptNextOwner() external {
        require (msg.sender == Next_Owner, "Can only accept preapproved new owner.");
        Owner = Next_Owner;
    }
    
    function () public payable {
    }

    function setSecretSigner(address New_Secret_Signer_Address) external onlyOwner {
        Secret_Signer_Address = New_Secret_Signer_Address;
    }
    
    function setCroupier(address New_Croupier) external onlyOwner {
        Croupier = New_Croupier;
    }

    function setMaxProfit(uint _Max_Profit) public onlyOwner {
        Max_Profit = _Max_Profit;
    }

    function increaseJackpot(uint Increase_Jackpot_Small, uint Increase_Jackpot_Medium, uint Increase_Jackpot_Large) external onlyOwner {
        require (Jackpot_Small_Pool + Jackpot_Medium_Pool + Jackpot_Large_Pool + Increase_Jackpot_Small + Increase_Jackpot_Medium + Increase_Jackpot_Large + Locked_in_Box <= address(this).balance, "Not enough eth in contract.");
        Jackpot_Small_Pool += uint128(Increase_Jackpot_Small);
        Jackpot_Medium_Pool += uint128(Increase_Jackpot_Medium);
        Jackpot_Large_Pool += uint128(Increase_Jackpot_Large);
    }
    
    function withdrawFunds(address Beneficiary, uint Withdraw_Amount) external onlyOwner {
        require (Jackpot_Small_Pool + Jackpot_Medium_Pool + Jackpot_Large_Pool + Locked_in_Box + Withdraw_Amount <= address(this).balance, "Can not withdraw more than idle eth in contract!");
        sendFunds(Beneficiary, Withdraw_Amount, Withdraw_Amount);
    }    
    
    function kill() external onlyOwner {
        require (Locked_in_Box == 0, "All games should be processed (settled or refunded) before self-destruct.");
        selfdestruct(Owner);
    }

     function placeGame(uint8 Roll_Under, uint256 Last_Commitable_Block, uint256 Commit, uint8 v, bytes32 r, bytes32 s) external payable {
        Game storage game = games[Commit];
        require (game.Gamer == address(0), "Game should be in a &#39;clean&#39; state.");

        // Validate input data ranges.
        uint Amount = msg.value;
        require (Amount >= Min_Ticket_Price, "Amount should be bigger than Min_Ticket_Price.");
        require (Roll_Under > 0 && Roll_Under < Game_Modulo, "Roll_Under should be within range.");

        require (block.number <= Last_Commitable_Block, "Commit has expired.");
        bytes32 Signature_Hash = keccak256(abi.encodePacked(Last_Commitable_Block, Commit));
        require (Secret_Signer_Address == ecrecover(Signature_Hash, v, r, s), "ECDSA signature is not valid.");

        uint Game_Cut = Amount * Game_Cut_Percentage / 100;

        require (Game_Cut + Jackpot_Ticket_Price <= Amount, "Amount is too less");
        uint Possible_Win_Amount = (Amount - Game_Cut - Jackpot_Ticket_Price) * 100 / Roll_Under;

        require (Possible_Win_Amount <= Amount + Max_Profit, "maxProfit limit violation.");

        // Lock funds.
        Locked_in_Box += uint128(Possible_Win_Amount);
        Jackpot_Small_Pool += uint128(Jackpot_Ticket_Price / 3);
        Jackpot_Medium_Pool += uint128(Jackpot_Ticket_Price / 3);
        Jackpot_Large_Pool += uint128(Jackpot_Ticket_Price / 3);




        require (Jackpot_Small_Pool + Jackpot_Medium_Pool + Jackpot_Large_Pool + Locked_in_Box <= address(this).balance, "Contract can not afford to lose this game.");

        emit Commit_Log(Commit);

        game.Amount = Amount;
        game.Roll_Under = uint8(Roll_Under);
        game.Played_Block_Number = uint40(block.number);
        game.Gamer = msg.sender;

    } 

    function revealResult(uint Reveal, bytes32 Block_Hash) external onlyCroupier {
        uint Commit = uint(keccak256(abi.encodePacked(Reveal)));
        Game storage game = games[Commit];      

        require (block.number > game.Played_Block_Number, "trying to reveal in the same block as playGame, or before.");
        require (block.number <= game.Played_Block_Number + Game_Expires_After, "Blockhash can&#39;t be queried by EVM.");
        require (blockhash(game.Played_Block_Number) == Block_Hash);


        revealResultCommon(game, Reveal, Block_Hash);
    }

    function revealResultUncleMerkleProof(uint Reveal, uint40 Canonical_Block_Number) external onlyCroupier {
        uint Commit = uint(keccak256(abi.encodePacked(Reveal)));
        Game storage game = games[Commit]; 

        require (block.number <= Canonical_Block_Number + Game_Expires_After, "Blockhash can&#39;t be queried by EVM.");

        // Verify placeGame receipt.
        requireCorrectReceipt(4 + 32 + 32 + 4);

        // Reconstruct canonical & uncle block hashes from a receipt merkle proof, verify them.
        bytes32 Canonical_Hash;
        bytes32 Uncle_Hash;
        (Canonical_Hash, Uncle_Hash) = verifyMerkleProof(Commit, 4 + 32 + 32);
        require (blockhash(Canonical_Block_Number) == Canonical_Hash);

        revealResultCommon(game, Reveal, Uncle_Hash);
    }

    function revealResultCommon(Game storage game, uint Reveal, bytes32 Entropy_Block_Hash) private {

        require (game.Amount != 0, "Can reveal only positive amount games");

        bytes32 Entropy = keccak256(abi.encodePacked(Reveal, Entropy_Block_Hash));
        uint Random_Number = uint(Entropy) % 100;

        uint Possible_Win_Amount = getPossibleWinAmount(game.Amount, game.Roll_Under);

        game.Amount = 0;

        uint Game_Win = 0;
        uint Jackpot_Large_Win = 0;
        uint Jackpot_Medium_Win = 0;
        uint Jackpot_Small_Win = 0;


        if (Random_Number < game.Roll_Under) {
            Game_Win = Possible_Win_Amount;
        }

        Locked_in_Box -= uint128(Possible_Win_Amount);
        
         
        uint Random_Number_For_Jackpot_Large = uint(Entropy) % 10000;        
        uint Random_Number_For_Jackpot_Medium = uint(Random_Number_For_Jackpot_Large) % 1000;        
        uint Random_Number_For_Jackpot_Small = uint(Random_Number_For_Jackpot_Medium) % 100;        

        if (Random_Number_For_Jackpot_Large == 8888) {
            Jackpot_Large_Win = Jackpot_Large_Pool;
            Jackpot_Large_Pool = 0;
        }

        if (Jackpot_Large_Win > 0) {
            emit JackpotPayment(game.Gamer, Jackpot_Large_Pool, 0);
        }

        if (Random_Number_For_Jackpot_Medium == 777) {
            Jackpot_Medium_Win = Jackpot_Medium_Pool;
            Jackpot_Medium_Pool = 0;
        }

        if (Jackpot_Medium_Win > 0) {
            emit JackpotPayment(game.Gamer, Jackpot_Medium_Win, 1);
        }

        if (Random_Number_For_Jackpot_Small == 66) {
            Jackpot_Small_Win = Jackpot_Small_Pool;
            Jackpot_Small_Pool = 0;
        }

        if (Jackpot_Small_Win > 0) {
            emit JackpotPayment(game.Gamer, Jackpot_Small_Win, 2);
        }

        sendFunds(game.Gamer, Game_Win + Jackpot_Small_Win + Jackpot_Medium_Win + Jackpot_Large_Win == 0 ? 1 wei : Game_Win + Jackpot_Small_Win + Jackpot_Medium_Win + Jackpot_Large_Win, Game_Win);
        
    }

    function getPossibleWinAmount(uint Amount, uint Roll_Under) private pure returns (uint Possible_Win_Amount) {

        uint Game_Cut = Amount * Game_Cut_Percentage / 100;
        Possible_Win_Amount = (Amount - Game_Cut - Jackpot_Ticket_Price) * 100 / Roll_Under;


    }



    function refundGame(uint Commit) external {

        Game storage game = games[Commit];
        uint Amount = game.Amount;
        uint Roll_Under = game.Roll_Under;
        
        require (Amount != 0, "Amount shoud be bigger than 0");

        // Check that game has already expired.
        require (block.number > game.Played_Block_Number + Game_Expires_After, "Game result still can be revealed");


        game.Amount = 0;

        uint Game_Cut = Amount * Game_Cut_Percentage / 100;
        uint Possible_Win_Amount = (Amount - Game_Cut - Jackpot_Ticket_Price) * 100 / Roll_Under;



        Locked_in_Box -= uint128(Possible_Win_Amount);
        Jackpot_Small_Pool -= uint128(Jackpot_Ticket_Price / 3);
        Jackpot_Medium_Pool -= uint128(Jackpot_Ticket_Price / 3);
        Jackpot_Large_Pool -= uint128(Jackpot_Ticket_Price / 3);
        
        sendFunds(game.Gamer, Amount, Amount);
    } 

    function sendFunds(address Beneficiary, uint Amount, uint Success_Log_Amount) private {
        if (Beneficiary.send(Amount)) {
            emit Payment(Beneficiary, Success_Log_Amount);
        } else {
            emit FailedPayment(Beneficiary, Amount);
        }
    }

    function verifyMerkleProof(uint seedHash, uint offset) pure private returns (bytes32 blockHash, bytes32 uncleHash) {
        // (Safe) assumption - nobody will write into RAM during this method invocation.
        uint scratchBuf1;  assembly { scratchBuf1 := mload(0x40) }

        uint uncleHeaderLength; uint blobLength; uint shift; uint hashSlot;

        // Verify merkle proofs up to uncle block header. Calldata layout is:
        //  - 2 byte big-endian slice length
        //  - 2 byte big-endian offset to the beginning of previous slice hash within the current slice (should be zeroed)
        //  - followed by the current slice verbatim
        for (;; offset += blobLength) {
            assembly { blobLength := and(calldataload(sub(offset, 30)), 0xffff) }
            if (blobLength == 0) {
                // Zero slice length marks the end of uncle proof.
                break;
            }

            assembly { shift := and(calldataload(sub(offset, 28)), 0xffff) }
            require (shift + 32 <= blobLength, "Shift bounds check.");

            offset += 4;
            assembly { hashSlot := calldataload(add(offset, shift)) }
            require (hashSlot == 0, "Non-empty hash slot.");

            assembly {
                calldatacopy(scratchBuf1, offset, blobLength)
                mstore(add(scratchBuf1, shift), seedHash)
                seedHash := sha3(scratchBuf1, blobLength)
                uncleHeaderLength := blobLength
            }
        }

        // At this moment the uncle hash is known.
        uncleHash = bytes32(seedHash);

        // Construct the uncle list of a canonical block.
        uint scratchBuf2 = scratchBuf1 + uncleHeaderLength;
        uint unclesLength; assembly { unclesLength := and(calldataload(sub(offset, 28)), 0xffff) }
        uint unclesShift;  assembly { unclesShift := and(calldataload(sub(offset, 26)), 0xffff) }
        require (unclesShift + uncleHeaderLength <= unclesLength, "Shift bounds check.");

        offset += 6;
        assembly { calldatacopy(scratchBuf2, offset, unclesLength) }
        memcpy(scratchBuf2 + unclesShift, scratchBuf1, uncleHeaderLength);

        assembly { seedHash := sha3(scratchBuf2, unclesLength) }

        offset += unclesLength;

        // Verify the canonical block header using the computed sha3Uncles.
        assembly {
            blobLength := and(calldataload(sub(offset, 30)), 0xffff)
            shift := and(calldataload(sub(offset, 28)), 0xffff)
        }
        require (shift + 32 <= blobLength, "Shift bounds check.");

        offset += 4;
        assembly { hashSlot := calldataload(add(offset, shift)) }
        require (hashSlot == 0, "Non-empty hash slot.");

        assembly {
            calldatacopy(scratchBuf1, offset, blobLength)
            mstore(add(scratchBuf1, shift), seedHash)

            // At this moment the canonical block hash is known.
            blockHash := sha3(scratchBuf1, blobLength)
        }
    }
    
     function requireCorrectReceipt(uint offset) view private {
        uint leafHeaderByte; assembly { leafHeaderByte := byte(0, calldataload(offset)) }

        require (leafHeaderByte >= 0xf7, "Receipt leaf longer than 55 bytes.");
        offset += leafHeaderByte - 0xf6;

        uint pathHeaderByte; assembly { pathHeaderByte := byte(0, calldataload(offset)) }

        if (pathHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require (pathHeaderByte >= 0x80 && pathHeaderByte <= 0xb7, "Path is an RLP string.");
            offset += pathHeaderByte - 0x7f;
        }

        uint receiptStringHeaderByte; assembly { receiptStringHeaderByte := byte(0, calldataload(offset)) }
        require (receiptStringHeaderByte == 0xb9, "Receipt string is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint receiptHeaderByte; assembly { receiptHeaderByte := byte(0, calldataload(offset)) }
        require (receiptHeaderByte == 0xf9, "Receipt is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint statusByte; assembly { statusByte := byte(0, calldataload(offset)) }
        require (statusByte == 0x1, "Status should be success.");
        offset += 1;

        uint cumGasHeaderByte; assembly { cumGasHeaderByte := byte(0, calldataload(offset)) }
        if (cumGasHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require (cumGasHeaderByte >= 0x80 && cumGasHeaderByte <= 0xb7, "Cumulative gas is an RLP string.");
            offset += cumGasHeaderByte - 0x7f;
        }

        uint bloomHeaderByte; assembly { bloomHeaderByte := byte(0, calldataload(offset)) }
        require (bloomHeaderByte == 0xb9, "Bloom filter is always 256 bytes long.");
        offset += 256 + 3;

        uint logsListHeaderByte; assembly { logsListHeaderByte := byte(0, calldataload(offset)) }
        require (logsListHeaderByte == 0xf8, "Logs list is less than 256 bytes long.");
        offset += 2;

        uint logEntryHeaderByte; assembly { logEntryHeaderByte := byte(0, calldataload(offset)) }
        require (logEntryHeaderByte == 0xf8, "Log entry is less than 256 bytes long.");
        offset += 2;

        uint addressHeaderByte; assembly { addressHeaderByte := byte(0, calldataload(offset)) }
        require (addressHeaderByte == 0x94, "Address is 20 bytes long.");

        uint logAddress; assembly { logAddress := and(calldataload(sub(offset, 11)), 0xffffffffffffffffffffffffffffffffffffffff) }
        require (logAddress == uint(address(this)));
    }
    
    // Memory copy.
    function memcpy(uint dest, uint src, uint len) pure private {
        // Full 32 byte words
        for(; len >= 32; len -= 32) {
            assembly { mstore(dest, mload(src)) }
            dest += 32; src += 32;
        }

        // Remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
   
}