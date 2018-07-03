pragma solidity ^0.4.9;

contract RPS{
    address public j1; // The first player creating the contract.
    address public j2; // The second player.
    enum Move {Null, Rock, Paper, Scissors, Spock, Lizard} // Possible moves. Note that if the parity of the moves is the same the lower one wins, otherwise the higher one. 
    bytes32 public c1Hash; // Commitment of j1.
    Move public c2; // Move of j2. Move.Null before he played.
    uint256 public stake; // Amout bet by each party.
    uint256 public TIMEOUT = 5 minutes; // If some party takes more than TIMEOUT to respond, the other can call TIMEOUT to win.
    uint256 public lastAction; // The time of the last action. Usefull to determine if someone has timed out.
    
    /** @dev Constructor. Must send the amount at stake when creating the contract. Note that the move and salt must be saved.
     *  @param _c1Hash Must be equal to keccak256(c1,salt) where c1 is the move of the j1.
     */
    function RPS(bytes32 _c1Hash, address _j2) payable {
        stake = msg.value; // La mise correspond &#224; la quantit&#233; d&#39;ethers envoy&#233;s.
        j1=msg.sender;
        j2=_j2;
        c1Hash=_c1Hash;
        lastAction=now;
    }
    
    /** @dev To be called by j2 and provided stake.
     *  @param _c2 The move submitted by j2.
     */
    function play(Move _c2) payable {
        require(c2==Move.Null); // J2 has not played yet.
        require(msg.value==stake); // J2 has paid the stake.
        require(msg.sender==j2); // Only j2 can call this function.
            
        c2=_c2;
        lastAction=now;
    }
    
    /** @dev To be called by j1. Reveal the move and send the ETH to the winning party or split them.
     *  @param _c1 The move played by j1.
     *  @param _salt The salt used when submitting the commitment when the constructor was called.
     */
    function solve(Move _c1, uint256 _salt) {
        require(c2!=Move.Null); // J2 must have played.
        require(msg.sender==j1); // J1 can call this.
        require(keccak256(_c1,_salt)==c1Hash); // Verify the value is the commited one.
        
        // If j1 or j2 throws at fallback it won&#39;t get funds and that is his fault.
        // Despite what the warnings say, we should not use transfer as a throwing fallback would be able to block the contract, in case of tie.
        if (win(_c1,c2))
            j1.send(2*stake);
        else if (win(c2,_c1))
            j2.send(2*stake);
        else {
            j1.send(stake);
            j2.send(stake);
        }
        stake=0;
    }
    
    /** @dev Let j2 get the funds back if j1 did not play.
     */
    function j1Timeout() {
        require(c2!=Move.Null); // J2 already played.
        require(now > lastAction + TIMEOUT); // Timeout time has passed.
        j2.send(2*stake);
        stake=0;
    }
    
    /** @dev Let j1 take back the funds if j2 never play.
     */
    function j2Timeout() {
        require(c2==Move.Null); // J2 has not played.
        require(now > lastAction + TIMEOUT); // Timeout time has passed.
        j1.send(stake);
        stake=0;
    }
    
    /** @dev Is this move winning over the other.
     *  @param _c1 The first move.
     *  @param _c2 The move the first move is considered again.
     *  @return w True if c1 beats c2. False if c1 is beaten by c2 or in case of tie.
     */
    function win(Move _c1, Move _c2) constant returns (bool w) {
        if (_c1 == _c2)
            return false; // They played the same so no winner.
        else if (_c1==Move.Null)
            return false; // They did not play.
        else if (uint(_c1)%2==uint(_c2)%2) 
            return (_c1<_c2);
        else
            return (_c1>_c2);
    }
    
}