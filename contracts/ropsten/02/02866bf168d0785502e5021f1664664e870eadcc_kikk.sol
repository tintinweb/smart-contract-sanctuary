pragma solidity ^0.4.25;

contract kikk {
    Profil[] public participants;
    string public messageSpecial;
    
    struct Profil {
        string nom;
        string linkedin;
    }
    
    constructor() {
        messageSpecial = "Merci Hassan Sefrioui! C’&#233;tait un plaisir de faire ta connaissance.";
        
        participants.push(Profil({
            nom: "Suyash Sumaroo",
            linkedin: "https://www.linkedin.com/in/suyashsumaroo/"
        }));

	    participants.push(Profil({
            nom: "Travailleur David",
            linkedin: "https://www.linkedin.com/in/travailleur-david-167ba7ba/"
        }));

	    participants.push(Profil({
            nom: "Julien Derandet",
            linkedin: "https://www.linkedin.com/in/julien-durandet/"
        }));

	    participants.push(Profil({
            nom: "Celine Delval",
            linkedin: "https://www.linkedin.com/in/cdelval/"
        }));

	    participants.push(Profil({
            nom: "Chloe Barabe",
            linkedin: "https://www.linkedin.com/in/chloebp/"
        }));

	    participants.push(Profil({
            nom: "Nilesh Latchooman",
            linkedin: "https://www.linkedin.com/in/nilesh-latchooman-398571103/"
        }));
    }
    
    function nomParticipant(uint index) public view returns (string participant) {
        return participants[index].nom;
    }
    
    function profilParticipant(uint index) public view returns (string participant) {
        return participants[index].linkedin;
    }
    
    function messageSpecial() public view returns (string message) {
        return messageSpecial;
    }
}