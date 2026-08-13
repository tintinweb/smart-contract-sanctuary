const fs = require("fs")

const getAllDirFiles = function (dirPath, arrayOfFiles) {
    let files = fs.readdirSync(dirPath)
    arrayOfFiles = arrayOfFiles || []

    files.forEach(function (file) {
        if (fs.statSync(dirPath + "/" + file).isDirectory()) {
            arrayOfFiles = getAllDirFiles(dirPath + "/" + file, arrayOfFiles)
        } else {
            arrayOfFiles.push(file)
        }
    })

    return arrayOfFiles
}

function readJsonLines(string) {
    return string.split('\n')
        .map(line => line.trim())
        .filter(line => line)
        //.map(line => line.replace(/'/g,'"'))
        .map(line => JSON.parse(line));
}

class Counter {
    constructor() {
        this.data = {};
    }
    add(name) {
        if (!this.data[name]) {
            this.data[name] = 1;
            return;
        }
        this.data[name]++;
    }
    toJSON() {
        return this.data;
    }
    topX(x) {
        var sortable = [];
        for (var k in this.data) {
            sortable.push([k, this.data[k]]);
        }
        return sortable.sort(function (a, b) {
            return b[1] - a[1];
        }).slice(0, x);
    }
}

class Stats {
    constructor(name) {
        this.stats = {
            name: name,
            fileCount: 0,
            compiler: new Counter(),
            names: new Counter(),
            dates: new Counter()
        };
    }
    processFiles(files) {
        this.stats.fileCount = files.length;
    }
    processSummaryFile(contractsJson) {
        readJsonLines(fs.readFileSync(contractsJson, { encoding: "utf-8" }))
            .forEach(entry => {
                if (entry.err) return;
                if (entry.compiler) this.stats.compiler.add(entry.compiler);
                else if (entry.compile_version) this.stats.compiler.add(entry.compile_version);
                if (entry.name) this.stats.names.add(entry.name);
                if (entry.date) this.stats.dates.add(entry.date);
                else if (entry.date_created) this.stats.dates.add(dateFormat(new Date(entry.date_created),"%m/%d/%Y"))
            });
    }
    toJSON() {
        return JSON.stringify(this.stats)
    }
}

function dateFormat(date, fstr, utc) {
    utc = utc ? 'getUTC' : 'get';
    return fstr.replace(/%[YmdHMS]/g, function (m) {
        switch (m) {
            case '%Y': return date[utc + 'FullYear'](); // no leading zeros required
            case '%m': m = 1 + date[utc + 'Month'](); break;
            case '%d': m = date[utc + 'Date'](); break;
            case '%H': m = date[utc + 'Hours'](); break;
            case '%M': m = date[utc + 'Minutes'](); break;
            case '%S': m = date[utc + 'Seconds'](); break;
            default: return m.slice(1); // unknown code, remove %
        }
        // add leading zero if required
        return ('0' + m).slice(-2);
    });
}

function sortDateArray(data) {

    return data.sort(function (a, b) {
        //4/30/2021
        t = a.split('/')
        a = [];
        a[0] = t[1].padStart(2, "0");
        a[1] = t[0].padStart(2, "0");
        a[2] = t[2]

        a = a.reverse().join('');

        t = b.split('/')
        b = [];
        b[0] = t[1].padStart(2, "0");
        b[1] = t[0].padStart(2, "0");
        b[2] = t[2]

        b = b.reverse().join('');

        return a > b ? 1 : a < b ? -1 : 0;
    });
}


function createReport(targets, flavor) {

    let totals = {
        fileCount: 0,
        uniqueContractNames: 0,
    }

    for (const [name, dirpath] of Object.entries(targets)) {
        let files = getAllDirFiles(dirpath).filter(f => f.endsWith(".sol"));

        let s = new Stats(name)
        s.processFiles(files);
        s.processSummaryFile(dirpath + "/contracts.json");
        totals.fileCount += s.stats.fileCount;
        totals.uniqueContractNames += Object.keys(s.stats.names.data).length


        let sortedDates = sortDateArray(Object.keys(s.stats.dates.data));
        console.log(`
### ${name}

**SourceUnits:** \`${s.stats.fileCount}\`   
**Unique Submissions (Name):** \`${Object.keys(s.stats.names.data).length}\`   

**First Submission:** \`${sortedDates[0]}\`    
**Most Recent Submission:** \`${sortedDates[sortedDates.length - 1]}\`   

#### Top 10

**Compiler:** 
   * ${s.stats.compiler.topX(10).map(([name, count]) => `\`${name}\` (${count})`).join('\n   * ')}   

**Names:**
   * ${s.stats.names.topX(10).map(([name, count]) => `\`${name}\` (${count})`).join('\n   * ')}   

**Submission Dates:** 
   * ${s.stats.dates.topX(10).map(([name, count]) => `\`${name}\` (${count})`).join('\n   * ')}   
        `)
    }

    console.log(`
### ___totals___

**SourceUnits:** \`${totals.fileCount}\`   
**Unique Contract Names (submissions):** \`${totals.uniqueContractNames}\`   
        `)

    return totals;

}


console.log(`# Smart-Contract-Sanctuary - STATS 📊

* [Ethereum](#ethereum)
  * Mainnet
  * Ropsten
  * Goerli
  * Kovan
  * Rinkeby
* [Binance Chain](#binance-chain)
  * Mainnet
  * Testnet
* [Polygon/Matic](#polygon-matic)
  * Mainnet
  * Mumbai
* [Tron](#Tron)
  * Mainnet

_______________

<sup>
last updated: ${new Date()}
</sup>

## Ethereum
`);


createReport({
    Mainnet: "../contracts/mainnet",
    Ropsten: "../contracts/ropsten",
    Goerli: "../contracts/goerli",
    Kovan: "../contracts/kovan",
    Rinkeby: "../contracts/rinkeby",
});

console.log(`
--------

## Binance Chain
`);

createReport({
    Mainnet: "../contracts_bscscan/mainnet",
    Testnet: "../contracts_bscscan/testnet",
});

console.log(`
-------

## Polygon Matic

`);

createReport({
    Mainnet: "../contracts_polygonscan/mainnet",
    Mumbai: "../contracts_polygonscan/mumbai",
});

console.log(`
-------

## Tron

`);

createReport({
    Mainnet: "../contracts_tronscan/mainnet",
});