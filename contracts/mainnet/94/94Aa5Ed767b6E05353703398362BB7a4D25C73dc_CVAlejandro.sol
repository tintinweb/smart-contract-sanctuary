pragma solidity ^0.4.0;



contract Owned {
    address owner;

    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        }
    }

    function Owned() {
        owner = msg.sender;
    }
}

contract Mortal is Owned {

    function kill() onlyOwner {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }

}

contract CVExtender {

    function getDescription() constant returns (string);
    function getTitle() constant returns (string);
    function getAuthor() constant returns (string, string);
    function getAddress() constant returns (string);

    function elementsAreSet() constant returns (bool) {
        //Normally I&#39;d do whitelisting, but for sake of simplicity, lets do blacklisting

        bytes memory tempEmptyStringTest = bytes(getDescription());
        if(tempEmptyStringTest.length == 0) {
            return false;
        }
        tempEmptyStringTest = bytes(getTitle());
        if(tempEmptyStringTest.length == 0) {
            return false;
        }
        var (testString1, testString2) = getAuthor();

        tempEmptyStringTest = bytes(testString1);
        if(tempEmptyStringTest.length == 0) {
            return false;
        }
        tempEmptyStringTest = bytes(testString2);
        if(tempEmptyStringTest.length == 0) {
            return false;
        }
        tempEmptyStringTest = bytes(getAddress());
        if(tempEmptyStringTest.length == 0) {
            return false;
        }
        return true;
    }
}


contract CVAlejandro is Mortal, CVExtender {

    string[] _experience;
    string[] _education;
    string[] _language;

    string _name;
    string _summary;
    string _email;
    string _link;
    string _description;
    string _title;

    // Social
    string _linkedIn;
    string _twitter;
    string _gitHub;



    function CVAlejandro() {

        // Main
        _name = &quot;Alejandro Saucedo&quot;;
        _email = &quot;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5c3d1c397124723533">[email&#160;protected]</a>&quot;;
        _link = &quot;https://github.com/axsauze/ethereum-solidity-cv-contract&quot;;
        _description = &quot;CTO. Manager. Engineer.&quot;;
        _title = &quot;Alejandro ETH CV&quot;;
        _summary = &quot;My experience ranges from chief technology officer, to engineering manager, to hands on software/devops engineer at startups and tech giants. I have designed and led the development of multiple software projects, and I have coordinated multiple national and global initiatives. I have deep technical knowledge, as well as managerial, leadership and people skills. I am highly driven by impact, and I strongly abide by my values.&quot;;

        // Social
        _linkedIn = &quot;http://linkedin.com/in/axsaucedo&quot;;
        _gitHub = &quot;https://github.com/axsauze&quot;;
        _twitter = &quot;https://twitter.com/axsaucedo&quot;;

        // Experience
        _experience.push(&quot;J.P. Morgan, Java Engineer&quot;);
        _experience.push(&quot;CTVE Shanghai China, English Teacher & Coordinator&quot;);
        _experience.push(&quot;Bloomberg LP, Software Engineer Intern&quot;);
        _experience.push(&quot;WakeUpRoulette, Founder & Chief Technology Officer&quot;);
        _experience.push(&quot;GitHack, Founder & Open Source Lead Engineer&quot;);
        _experience.push(&quot;Founders4Schools, Advisor&quot;);
        _experience.push(&quot;Techstars, Global Facilitator&quot;);
        _experience.push(&quot;HackaGlobal, Founder & Managing Director&quot;);
        _experience.push(&quot;Bloomberg LP, Full Stack Software Engineer&quot;);
        _experience.push(&quot;Hack Partners, Co-founder & Chief Technology Officer&quot;);
        _experience.push(&quot;Entrepreneur First, Entrepreneur in Residence&quot;);
        _experience.push(&quot;Exponential Technologies, Founder & Chief Engineer&quot;);

        // Education
        _education.push(&quot;University of Southampton, BEng. Software Engineering (1st Class Honours)&quot;);

        // Languages
        _language.push(&quot;English&quot;);
        _language.push(&quot;Spanish&quot;);
        _language.push(&quot;Mandarin&quot;);
        _language.push(&quot;Russian&quot;);
        _language.push(&quot;Portuguese&quot;);
    }

    // UTIL

    function popFromStringArray(string[] storage array) internal {
        if(array.length < 1) return;

        array.length--;
    }

    function strArrayConcat(string[] storage array) internal returns (string){

        uint totalSize = 0;
        uint i = 0;
        uint j = 0;
        uint strIndex = 0;
        bytes memory currStr;

        for(i = 0; i < array.length; i++) {
            currStr = bytes(array[i]);
            // We add the total plus the \n character
            totalSize = totalSize + currStr.length + 1;
        }

        string memory stringBuffer = new string(totalSize);
        bytes memory bytesResult = bytes(stringBuffer);

        for(i = 0; i < array.length; i++) {
            currStr = bytes(array[i]);

            for(j = 0; j < currStr.length; j++) {
                bytesResult[strIndex] = currStr[j];
                strIndex = strIndex + 1;
            }

            bytesResult[strIndex] = byte(&quot;\n&quot;);
            strIndex = strIndex + 1;
        }

        return string(bytesResult);
    }


    // MAIN

    function getEmail() constant returns(string) {
        return _email;
    }

    function setEmail(string email) onlyOwner {
        _email = email;
    }

    function getName() constant returns(string) {
        return _name;
    }

    function setName(string name) onlyOwner {
        _name = name;
    }

    function getSummary() constant returns(string) {
        return _summary;
    }

    function setSummary(string summary) onlyOwner {
        _summary = summary;
    }



    // EXPERIENCE

    function getExperience() constant returns(string) {
        return strArrayConcat(_experience);
    }

    function addExperience(string experience) onlyOwner {
        _experience.push(experience);
    }

    function popExperience() onlyOwner {
        popFromStringArray(_experience);
    }

    function getEducation() constant returns(string) {
        return strArrayConcat(_education);
    }

    function addEducation(string education) onlyOwner {
        _education.push(education);
    }

    function popEducation() onlyOwner {
        popFromStringArray(_education);
    }

    function getLanguage() constant returns(string) {
        return strArrayConcat(_language);
    }

    function addLanguage(string language) onlyOwner {
        _language.push(language);
    }

    function popLanguage() onlyOwner {
        popFromStringArray(_language);
    }

    function getLinkedIn() constant returns(string) {
        return _linkedIn;
    }

    function setLinkedIn(string linkedIn) onlyOwner {
        _linkedIn = linkedIn;
    }

    function getGitHub() constant returns(string) {
        return _gitHub;
    }

    function setGitHub(string gitHub) onlyOwner {
        _gitHub = gitHub;
    }

    function getTwitter() constant returns(string) {
        return _twitter;
    }

    function setTwitter(string twitter) onlyOwner {
        _twitter = twitter;
    }



    // INHERITED from CVExtender

    function getAddress() constant returns(string) {
        return _link;
    }

    function setAddress(string link) onlyOwner {
        _link = link;
    }

    function getDescription() constant returns(string) {
        return _description;
    }

    function setDescription(string description) onlyOwner {
        _description = description;
    }

    function getTitle() constant returns(string) {
        return _title;
    }

    function setTitle(string title) onlyOwner {
        _title = title;
    }

    function getAuthor() constant returns(string, string) {
        return (_name, _email);
    }

}