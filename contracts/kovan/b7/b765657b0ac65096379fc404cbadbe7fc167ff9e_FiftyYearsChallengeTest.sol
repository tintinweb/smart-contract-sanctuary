/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity ^0.4.22;


// contract analysis

// 0. objectif: vider le contrat
// 1. voir la structure mémoire: queue, head, owner
// 
contract FiftyYearsChallengeTest {
    struct Contribution {
        uint256 amount;
        uint256 unlockTimestamp;
    }


    Contribution[] queue;
    uint256 head;

    address owner;


    // slot 0: queue.size
    // slot 1: head
    // slot 2: owner

    // uint256(keccak256(0)) + (0 * elementSize) : queue[0] 
    // uint256(keccak256(0)) + (1 * elementSize) : queue[1] 
    // uint256(keccak256(0)) + (2 * elementSize) : queue[2] 


    // au démarrage on a donc:
    // slot 0: 1
    // slot 1: 0
    // slot 2: moi

    // uint256(keccak256(0)) + (0 * elementSize) : Contribution(1 ether, nom + 50 years)


    // si je veux withdraw direct, je dois ecraser ceci: queue[0].unlockTimestamp


    // EXPLOIT POSSIBLE
    // upsert(1, uint256 timestamp)
    // avec timestamp >= queue[queue.length - 1].unlockTimestamp + 1 days

    // -->
    //        contribution.amount = msg.value --> va ecraser queue.size avec valeur N
    //        contribution.unlockTimestamp = timestamp; --> va ecraser head
    //        queue.push(contribution); --> selon msg.value, va ecrire en N+1

    // example msg.value = 1
    // -->
    //        contribution.amount = msg.value --> queue.size = 1 --> inchangé
    //        contribution.unlockTimestamp = timestamp; --> head vaudra 50 ans + 1 jour
    //        queue.push(contribution); --> cette contribution sera pushée en 2 eme position

    // --> en theorie, j'aurai 2 contributions de 1 ether mais head corrompu --> marche pas


    // example msg.value = 0
    // -->
    //        contribution.amount = msg.value --> queue.size = 0 
    //        contribution.unlockTimestamp = timestamp; --> head vaudra 50 ans + N jour
    //        queue.push(contribution); --> cette contribution sera pushée en 0
    // tout est annulé et head corrompu

    // MAIS
    // example msg.value = 0 timestamp = maxint
    // -->
    //        contribution.amount = msg.value --> queue.size = 0 
    //        contribution.unlockTimestamp = maxint = head
    //        queue.push(contribution); --> cette contribution sera pushée en 0
    // tout est annulé et head vaut maxint
    // PUIS
    // example msg.value = 0 timestamp = ce wu'on veut, now par example ou 0
    // -->
    //        contribution.amount = msg.value --> queue.size = 0 
    //        contribution.unlockTimestamp = 0 = head
    //        queue.push(contribution); --> cette contribution sera pushée en 0
    // j'ai une contribution de 0 en 0 vaut 0

    // RESTE UN SOUCI: mes queue[i].amount sont nuls

    // SOLUTION
    // --> faut pas toucher à la contribution 0
    // example msg.value = 1 timestamp = maxint
    // -->
    //        contribution.amount = msg.value --> queue.size = 1 
    //        contribution.unlockTimestamp = maxint = head
    //        queue.push(contribution); --> cette contribution sera pushée en 1
    // 0: 1, 50 years
    // 1: 1, mxint
    // head = 256
    
    // PUIS
    // example msg.value = 2 timestamp = ce qu'on veut, now par example ou 0
    // -->
    //        contribution.amount = msg.value --> queue.size = 2 
    //        contribution.unlockTimestamp = 0 = head
    //        queue.push(contribution); --> cette contribution sera pushée en 2

    // 0: 1, 50 years
    // 1: 1, mxint
    // 2: 2, 0
    // head = 0
    // withdraw(2) devrait marcher

    // PB j'ai besoin de 3 eth pour hacker? 

    // KO car contribution est en fait à zero 
    // + en fait msg.value est en wei? du coup chelou que j'ai bien la bonne size???

    


    // en fait j'ai ça
    // 0: 1, 50 years
    // 1: 0, 0
    // 2: 0, 0
    // head = 0

    

    // tester cette stratégie sur ganache car si ça ne marche pas ca va couter cher
    // puis valider sur ropsten et regarder si une autre solution existe avec moins d'eth
    
    // rq: il doit y avoir une solution en passant par des kekkac(256) etc..

    function FiftyYearsChallengeTest(address player) public payable {
        require(msg.value == 0.01 ether);

        owner = player;
        queue.push(Contribution(msg.value, now + 50 years));
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }


    // UPDATE OU PUSH
    function upsert(uint256 index, uint256 timestamp) public payable 
    {
        // suis-je bien le owner?
        require(msg.sender == owner);

        if (index >= head && index < queue.length) 
        {
            // INDEX PRESENT DANS LA QUEUE --> ON UPDATE
            // BASE SUR HEAD
            // Update existing contribution amount without updating timestamp.
            Contribution storage contribution = queue[index];
            contribution.amount += msg.value;
        } 
        else 
        {
            // ON VA PUSHER UNE CONTRIBUTION 
            // TIMESTAMP = 1 JOUR DE PLUS QUE LA DERNIERE DE LA QUEUE
            // Append a new contribution. Require that each contribution unlock
            // at least 1 day after the previous one.
            // OVERFLOW POSSIBLE DANS CE REQUIRE
            require(timestamp >= queue[queue.length - 1].unlockTimestamp + 1 days);

            // BUG ICI PROBABLE --> ECRASEMENT MEMOIRE JE PENSE
            contribution.amount = msg.value;
            contribution.unlockTimestamp = timestamp;
            queue.push(contribution);
        }
    }

    // supposons withdraw(0)
    // -> le test de time passera pas
    function withdraw(uint256 index) public {
        require(msg.sender == owner);
        require(now >= queue[index].unlockTimestamp);

        // Withdraw this and any earlier contributions.
        uint256 total = 0;
        for (uint256 i = head; i <= index; i++) {
            total += queue[i].amount;

            // Reclaim storage.
            // CA MARCHE CA?
            // EN PLUS DANS UNE BOUCLE?
            delete queue[i];
        }

        // Move the head of the queue forward so we don't have to loop over
        // already-withdrawn contributions.
        // ON POSITIONNE LA QUEUE APRES CE QUI A ETE WITHDRAW
        head = index + 1;

        msg.sender.transfer(total);
    }
}