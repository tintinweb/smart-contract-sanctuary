pragma solidity 0.4.24;

contract game{
    
    struct Moves {
        bytes32 p1Move;
        bytes32 p2Move;
        uint wager;
    }
    
    enum ChallengeState { challenged, accepted, playing, evaluating }
    enum EvalState {win, lose, draw}
    
    mapping(bytes32 => Moves) public moves;
    mapping(bytes32 => ChallengeState) public pendingGame;
    mapping(address => uint) public moneys;
    mapping(bytes32 => mapping(bytes32 => EvalState)) public evulationMapping;
    address owner;
    
    constructor()
    {
        owner = msg.sender;
        
        evulationMapping[keccak256("Paper")][keccak256("Rock")] = EvalState.win;
        evulationMapping[keccak256("Paper")][keccak256("Scissors")] = EvalState.lose;
        evulationMapping[keccak256("Paper")][keccak256("Paper")] = EvalState.draw;
        evulationMapping[keccak256("Rock")][keccak256("Rock")] = EvalState.draw;
        evulationMapping[keccak256("Rock")][keccak256("Scissors")] = EvalState.win;
        evulationMapping[keccak256("Rock")][keccak256("Paper")] = EvalState.lose;
        evulationMapping[keccak256("Scissors")][keccak256("Rock")] = EvalState.lose;
        evulationMapping[keccak256("Scissors")][keccak256("Scissors")] = EvalState.draw;
        evulationMapping[keccak256("Scissors")][keccak256("Paper")] = EvalState.win;
    }
    
    function evaluate(address opponent, string movePassword, string move)
    external
    {
        bytes32 gameHash = getPairHash(msg.sender, opponent);
        
        require(pendingGame[gameHash] == ChallengeState.playing || pendingGame[gameHash] == ChallengeState.evaluating);
        
        bytes32 verifiedMove = keccak256(move, movePassword);
        
        if (opponent > msg.sender)
        {
            require(verifiedMove == moves[gameHash].p1Move);
            
            if(pendingGame[gameHash] == ChallengeState.playing)
            {
                pendingGame[gameHash] = ChallengeState.evaluating;
                
                moves[gameHash].p1Move = keccak256(move);
            }
            else
            {
                moneys[GetWinner(keccak256(move), msg.sender, moves[gameHash].p2Move, opponent)] += moves[gameHash].wager * 2;
            }
            
        }
        else
        {
            require(verifiedMove == moves[gameHash].p2Move);
            
            if(pendingGame[gameHash] == ChallengeState.playing)
            {
                pendingGame[gameHash] = ChallengeState.evaluating;
                
                moves[gameHash].p2Move = keccak256(move);
            }
            else
            {
                moneys[GetWinner(moves[gameHash].p1Move, opponent, keccak256(move), msg.sender)] += moves[gameHash].wager * 2;
            }
        }
    }
    
    function GetWinner(bytes32 p1Move, address p1Address, bytes32 p2Move, address p2Address)
    internal
    view
    returns (address)
    {
        if (evulationMapping[p1Move][p2Move] == EvalState.win)
            return p1Address;
        else if (evulationMapping[p1Move][p2Move] == EvalState.lose)
            return p2Address;
        return owner;
    }
    
    function challenge(address bastard)
    external
    payable
    {
        require(msg.value > 10 finney);
        bytes32 gameHash = getPairHash(msg.sender, bastard);
        pendingGame[gameHash] = ChallengeState.challenged;
        
        moves[gameHash].wager = msg.value;
    }
    
    function acceptChallenge(address challenger)
    external
    payable
    {
        bytes32 gameHash = getPairHash(msg.sender, challenger);
        
        require(msg.value == moves[gameHash].wager);
        pendingGame[gameHash] = ChallengeState.accepted;
    }
    
    function play(address opponent, bytes32 move)
    external
    {
        bytes32 gameHash = getPairHash(msg.sender, opponent);
        
        require(pendingGame[gameHash] == ChallengeState.accepted || pendingGame[gameHash] == ChallengeState.playing);
        
        if (opponent > msg.sender)
            moves[gameHash].p1Move = move;
        else
            moves[gameHash].p2Move = move;
            
        pendingGame[gameHash] = ChallengeState.playing;
    }
    
    function getPairHash(address _a, address _b)
    public
    pure
    returns (bytes32){
        return (_a < _b) ? keccak256(abi.encodePacked(_a, _b)) :  keccak256(abi.encodePacked(_b, _a));
    }
    
    function ()
    external
    payable
    {
        emit hello(msg.sender, msg.value);
    }
    
    event hello(address sender, uint amount);
    
}