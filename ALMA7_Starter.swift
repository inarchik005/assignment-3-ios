// =============================================================
//  Station ALMA-7: Rescue Protocol
//  iOS Mobile Development · Module 3 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER CODE section.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • Use the exact function names from the assignment PDF.
// =============================================================


// MARK: - =================== STARTER CODE ===================
// MARK: - Do not modify anything in this section

typealias Reading = (sensor: String, value: Int)

/// Splits a string at the first occurrence of the separator.
/// splitOnce("O2:87", by: ":") -> ("O2", "87")
/// splitOnce("hello", by: ":") -> nil
func splitOnce(_ line: String, by separator: Character) -> (String, String)? {
    guard let index = line.firstIndex(of: separator) else { return nil }
    let left = String(line[..<index])
    let right = String(line[line.index(after: index)...])
    return (left, right)
}

let rawLog = [
    "O2:87", "TEMP:-12", "O2:9x", "PRESS:101", "TEMP:abc", "O2:",
    "RAD:3", "O2:64", ":55", "TEMP:31", "PRESS:98", "O2:71",
    "RAD:-1", "TEMP:4", "PRESS:1o2", "O2:90"
]

class Tank {
    var level: Int
    init(level: Int) { self.level = level }
}

class Module {
    let name: String
    var oxygenTank: Tank?
    init(name: String, oxygenTank: Tank?) {
        self.name = name
        self.oxygenTank = oxygenTank
    }
}

class CrewMember {
    let name: String
    let role: String
    let priority: Int      // 1 = evacuated first
    var module: Module?    // nil = in open space
    init(name: String, role: String, priority: Int, module: Module?) {
        self.name = name
        self.role = role
        self.priority = priority
        self.module = module
    }
}

let lab  = Module(name: "Lab",  oxygenTank: Tank(level: 40))
let hab  = Module(name: "Hab",  oxygenTank: Tank(level: 12))
let dock = Module(name: "Dock", oxygenTank: nil)

let crew = [
    CrewMember(name: "Timur",   role: "Engineer",  priority: 3, module: lab),
    CrewMember(name: "Dana",    role: "Scientist", priority: 4, module: dock),
    CrewMember(name: "Aigerim", role: "Commander", priority: 1, module: hab),
    CrewMember(name: "Nurlan",  role: "Pilot",     priority: 2, module: nil)
]

var roster: [String: CrewMember] = [:]
for member in crew { roster[member.name] = member }

print("ALMA-7 systems online: \(rawLog.count) log lines, \(crew.count) crew members.")

// MARK: - ================= END OF STARTER CODE =================


// MARK: - =================== YOUR SOLUTION ===================
// MARK: Level 1 · Decoding Telemetry

// 1.1
func parseReading(_ raw: String) -> Reading? {
    guard let parts = splitOnce(raw, by: ":"),
          !parts.0.isEmpty,
          let value = Int(parts.1),
          parts.0 == "TEMP" || value >= 0
    else {
        return nil
    }
    return (sensor: parts.0, value: value)
}

// Tests for splitOnce (starter helper) and parseReading
let splitTest1 = splitOnce("O2:87", by: ":")
print("Test splitOnce 1: \(splitTest1?.0 ?? "nil") / \(splitTest1?.1 ?? "nil")")
let splitTest2 = splitOnce("hello", by: ":")
print("Test splitOnce 2 found separator: \(splitTest2 != nil)")

if let readingTest1 = parseReading("O2:87") {
    print("Test parseReading 1: \(readingTest1.sensor): \(readingTest1.value)")
} else {
    print("Test parseReading 1: invalid")
}
let readingTest2 = parseReading("RAD:-1")
print("Test parseReading 2 is nil: \(readingTest2 == nil)")
let readingTest3 = parseReading("TEMP:-12")
print("Test parseReading 3 allows negative temperature: \(readingTest3 != nil)")

// 1.2
func parseLog(_ lines: [String]) -> (valid: [Reading], invalidCount: Int) {
    var validReadings: [Reading] = []
    var invalidCount = 0

    for line in lines {
        if let reading = parseReading(line) {
            validReadings.append(reading)
        } else {
            invalidCount += 1
        }
    }

    return (valid: validReadings, invalidCount: invalidCount)
}

let logResult = parseLog(rawLog)
let A = logResult.invalidCount
print("Level 1 - Valid readings: \(logResult.valid.count), invalid readings: \(A)")
let smallLogResult = parseLog(["O2:10", "TEMP:abc"])
print("Test parseLog 2: valid = \(smallLogResult.valid.count), invalid = \(smallLogResult.invalidCount)")
let emptyLogResult = parseLog([])
print("Test parseLog empty input: valid = \(emptyLogResult.valid.count), invalid = \(emptyLogResult.invalidCount)")


// MARK: Level 2 · Analysis

// 2.1 - Write our own selection function; do not use filter.
func select(_ readings: [Reading], where isIncluded: (Reading) -> Bool) -> [Reading] {
    var selectedReadings: [Reading] = []

    for reading in readings {
        if isIncluded(reading) {
            selectedReadings.append(reading)
        }
    }

    return selectedReadings
}

func values(of readings: [Reading]) -> [Int] {
    var result: [Int] = []

    for reading in readings {
        result.append(reading.value)
    }

    return result
}

let o2Readings = select(logResult.valid) { $0.sensor == "O2" }
let temperatureReadings = select(logResult.valid) { $0.sensor == "TEMP" }
print("Level 2 - O2 readings: \(o2Readings.count)")
print("Test select for TEMP readings: \(temperatureReadings.count)")
print("Test values for O2 readings: \(values(of: o2Readings))")
print("Test values for all valid readings: \(values(of: logResult.valid))")

// 2.2
func stats(of values: [Int]) -> (min: Int, max: Int, average: Double)? {
    guard let firstValue = values.first else {
        return nil
    }

    var minimum = firstValue
    var maximum = firstValue
    var total = 0

    for value in values {
        if value < minimum {
            minimum = value
        }
        if value > maximum {
            maximum = value
        }
        total += value
    }

    let average = Double(total) / Double(values.count)
    return (min: minimum, max: maximum, average: average)
}

// The variadic version delegates to stats(of:) in a single expression.
func stats(_ values: Int...) -> (min: Int, max: Int, average: Double)? { stats(of: values) }

let o2Statistics = stats(of: values(of: o2Readings))
let B = Int(o2Statistics?.average ?? 0)
print("Level 2 - O2 stats: \(String(describing: o2Statistics))")
print("Code fragment B (average O2 as Int): \(B)")
print("Test stats with empty array: \(String(describing: stats(of: [])))")
print("Test stats variadic with values: \(String(describing: stats(3, 8, 1)))")
print("Test stats variadic empty: \(String(describing: stats()))")

// 2.3 - The Closure Ladder: sort by reading value in descending order.
let sorted1 = logResult.valid.sorted(by: { (left: Reading, right: Reading) -> Bool in
    return left.value > right.value
})
let sorted2 = logResult.valid.sorted(by: { left, right in
    return left.value > right.value
})
let sorted3 = logResult.valid.sorted(by: { left, right in
    left.value > right.value
})
let sorted4 = logResult.valid.sorted(by: { $0.value > $1.value })
let sorted5 = logResult.valid.sorted { $0.value > $1.value }

func readingsMatch(_ first: [Reading], _ second: [Reading]) -> Bool {
    guard first.count == second.count else {
        return false
    }

    for index in first.indices {
        if first[index].sensor != second[index].sensor || first[index].value != second[index].value {
            return false
        }
    }

    return true
}

let closureLadderMatches = readingsMatch(sorted1, sorted2)
    && readingsMatch(sorted1, sorted3)
    && readingsMatch(sorted1, sorted4)
    && readingsMatch(sorted1, sorted5)
print("Level 2 - All five closure sort results match: \(closureLadderMatches)")
print("Test readingsMatch identical results: \(readingsMatch(sorted1, sorted1))")
print("Test readingsMatch different lengths: \(readingsMatch(sorted1, []))")


// MARK: Level 3 · Temperature Stabilization

// 3.1
func heatUp(_ t: Int) -> Int { t + 5 }
func coolDown(_ t: Int) -> Int { t - 3 }
func hold(_ t: Int) -> Int { t }

func chooseProtocol(for temp: Int) -> (Int) -> Int {
    if temp < 18 {
        return heatUp
    } else if temp > 24 {
        return coolDown
    } else {
        return hold
    }
}

print("Test heatUp: \(heatUp(10)), \(heatUp(20))")
print("Test coolDown: \(coolDown(30)), \(coolDown(25))")
print("Test hold: \(hold(18)), \(hold(24))")
print("Test chooseProtocol low: \(chooseProtocol(for: 10)(10))")
print("Test chooseProtocol high: \(chooseProtocol(for: 30)(30))")
print("Test chooseProtocol safe range: \(chooseProtocol(for: 22)(22))")

// 3.2
func runUntilStable(from start: Int, maxSteps: Int = 10) -> (finalTemp: Int, steps: Int, isStable: Bool) {
    var temperature = start
    var steps = 0

    while (temperature < 18 || temperature > 24) && steps < maxSteps {
        let protocolFunction = chooseProtocol(for: temperature)
        temperature = protocolFunction(temperature)
        steps += 1
    }

    let isStable = temperature >= 18 && temperature <= 24
    return (finalTemp: temperature, steps: steps, isStable: isStable)
}

let stabilizationTest1 = runUntilStable(from: 31)
let stabilizationTest2 = runUntilStable(from: -100, maxSteps: 5)
print("Test runUntilStable from 31: \(stabilizationTest1)")
print("Test runUntilStable from -100: \(stabilizationTest2)")

let temperatureStats = stats(of: values(of: temperatureReadings))
let lowestValidTemperature = temperatureStats?.min ?? 0
let stabilizationForLowestTemperature = runUntilStable(from: lowestValidTemperature)
let C = stabilizationForLowestTemperature.steps
print("Code fragment C (steps from lowest valid TEMP reading \(lowestValidTemperature)): \(C)")


// MARK: Level 4 · The Crew

// 4.1 - One-line body using optional chaining.
func oxygenLevel(of member: CrewMember) -> Int? { member.module?.oxygenTank?.level }

// 4.2 - Use guard let for missing data and ?? for the location label.
func status(of member: CrewMember) -> String {
    let location = member.module?.name ?? "open space"

    guard let module = member.module else {
        return "\(member.name): no data (\(location))"
    }

    guard let level = module.oxygenTank?.level else {
        return "\(member.name): no data (\(location))"
    }

    let condition = level < 20 ? "CRITICAL" : "OK"
    return "\(member.name): \(level)% \(condition)"
}

print("Test oxygenLevel Timur: \(String(describing: oxygenLevel(of: crew[0])))")
print("Test oxygenLevel Dana: \(String(describing: oxygenLevel(of: crew[1])))")
print("Test oxygenLevel Nurlan: \(String(describing: oxygenLevel(of: crew[3])))")
print("Test status Aigerim: \(status(of: crew[2]))")
print("Test status Dana: \(status(of: crew[1]))")
for member in crew {
    print("Crew status: \(status(of: member))")
}

// 4.3
@discardableResult
func transferOxygen(from source: inout Int, to target: inout Int, amount: Int) -> Int {
    guard amount > 0, source > 0, target < 100 else {
        return 0
    }

    let availableFromSource = min(amount, source)
    let targetCapacity = 100 - target
    let transferred = min(availableFromSource, targetCapacity)

    source -= transferred
    target += transferred
    return transferred
}

var transferredToHab = 0
if let labTank = lab.oxygenTank, let habTank = hab.oxygenTank {
    transferredToHab = transferOxygen(from: &labTank.level, to: &habTank.level, amount: 30)
}
print("Test transfer Lab to Hab: moved \(transferredToHab), Lab = \(lab.oxygenTank?.level ?? 0), Hab = \(hab.oxygenTank?.level ?? 0)")

var testSource = 10
var testTarget = 95
let limitedTransfer = transferOxygen(from: &testSource, to: &testTarget, amount: 20)
print("Test transfer limited by capacity: moved \(limitedTransfer), source = \(testSource), target = \(testTarget)")
var negativeSource = 10
var negativeTarget = 20
let negativeTransfer = transferOxygen(from: &negativeSource, to: &negativeTarget, amount: -5)
print("Test negative transfer: moved \(negativeTransfer), source = \(negativeSource), target = \(negativeTarget)")

let D = hab.oxygenTank?.level ?? 0
print("Code fragment D (Hab oxygen after transfer): \(D)")

// 4.4
func evacuationOrder(_ names: String..., roster: [String: CrewMember]) -> [String] {
    var foundMembers: [CrewMember] = []

    for name in names {
        guard let member = roster[name] else {
            print("Unknown crew member: \(name)")
            continue
        }
        foundMembers.append(member)
    }

    foundMembers.sort { $0.priority < $1.priority }

    var orderedNames: [String] = []
    for member in foundMembers {
        orderedNames.append(member.name)
    }

    return orderedNames
}

let evacuationTest1 = evacuationOrder("Dana", "Ghost", "Aigerim", "Timur", roster: roster)
print("Test evacuation order 1: \(evacuationTest1)")
let evacuationTest2 = evacuationOrder("Nurlan", "Unknown", roster: roster)
print("Test evacuation order 2: \(evacuationTest2)")


// MARK: Level 5 · The Saboteur's Logbook
// Original buggy code from the assignment, preserved as a comment for analysis:
/*
func reportOxygen(for member: CrewMember) -> String {
    let tank = member.module!.oxygenTank!
    return "\(member.name): \(tank.level)%"
}

func firstCritical(in crew: [CrewMember]) -> String {
    var result: String?
    for member in crew {
        if oxygenLevel(of: member)! < 20 {
            result = member.name
        }
    }
    return result!
}
*/

// Problem 1: member.module may be nil (Nurlan is in open space); force-unwrapping it traps.
// Problem 2: module.oxygenTank may be nil (Dana's Dock module has no tank); force-unwrapping it traps.
// Problem 3: oxygenLevel(of:) returns Int?; force-unwrapping nil for Dana or Nurlan traps.
// Problem 4: assigning result for every critical member overwrites earlier matches, so it returns the LAST critical member, not the first.
// Problem 5: result can stay nil when nobody is critical; result! then traps.

func reportOxygen(for member: CrewMember) -> String {
    guard let module = member.module else {
        return "\(member.name): no data (open space)"
    }

    guard let tank = module.oxygenTank else {
        return "\(member.name): no data (\(module.name))"
    }

    return "\(member.name): \(tank.level)%"
}

func firstCritical(in crew: [CrewMember]) -> String? {
    for member in crew {
        guard let level = oxygenLevel(of: member) else {
            continue
        }

        if level < 20 {
            return member.name
        }
    }

    return nil
}

print("Test reportOxygen Timur: \(reportOxygen(for: crew[0]))")
print("Test reportOxygen Dana: \(reportOxygen(for: crew[1]))")
print("Test reportOxygen Nurlan: \(reportOxygen(for: crew[3]))")
// Use a fresh copy of the original crew levels, because the transfer test above changes Lab and Hab.
let originalCrewForCriticalTest = [
    CrewMember(name: "Timur", role: "Engineer", priority: 3, module: Module(name: "Lab", oxygenTank: Tank(level: 40))),
    CrewMember(name: "Dana", role: "Scientist", priority: 4, module: Module(name: "Dock", oxygenTank: nil)),
    CrewMember(name: "Aigerim", role: "Commander", priority: 1, module: Module(name: "Hab", oxygenTank: Tank(level: 12))),
    CrewMember(name: "Nurlan", role: "Pilot", priority: 2, module: nil)
]
print("Test firstCritical with original crew levels: \(firstCritical(in: originalCrewForCriticalTest) ?? "none")")

// This test has two critical people. The old logic would overwrite the first match
// and return CriticalSecond; the corrected function returns CriticalFirst.
let criticalFirstTank = Tank(level: 10)
let criticalSecondTank = Tank(level: 5)
let criticalFirstModule = Module(name: "TestModule1", oxygenTank: criticalFirstTank)
let criticalSecondModule = Module(name: "TestModule2", oxygenTank: criticalSecondTank)
let criticalFirstMember = CrewMember(name: "CriticalFirst", role: "Test", priority: 1, module: criticalFirstModule)
let criticalSecondMember = CrewMember(name: "CriticalSecond", role: "Test", priority: 2, module: criticalSecondModule)
let logicBugTest = firstCritical(in: [criticalFirstMember, criticalSecondMember])
print("Test firstCritical logic fix: \(logicBugTest ?? "none")")
let noCriticalTank = Tank(level: 50)
let noCriticalMember = CrewMember(name: "SafeMember", role: "Test", priority: 1, module: Module(name: "SafeModule", oxygenTank: noCriticalTank))
print("Test firstCritical when nobody is critical: \(firstCritical(in: [noCriticalMember]) ?? "none")")


// MARK: Finale · Launch Code
let launchCode = "\(A)-\(B)-\(C)-\(D)"
print("LAUNCH CODE: \(launchCode)")


// MARK: Bonus
func makeAlarm(threshold: Int) -> (Int) -> Bool {
    var alarmCount = 0

    return { value in
        if value < threshold {
            alarmCount += 1
            print("Alarm #\(alarmCount): value \(value) is below threshold \(threshold)")
            return true
        }
        return false
    }
}

let oxygenAlarm = makeAlarm(threshold: 20)
print("Test oxygenAlarm normal reading: \(oxygenAlarm(25))")
print("Test oxygenAlarm first low reading: \(oxygenAlarm(15))")
print("Test oxygenAlarm second low reading: \(oxygenAlarm(10))")
let temperatureAlarm = makeAlarm(threshold: 0)
print("Test temperatureAlarm safe reading: \(temperatureAlarm(5))")
print("Test temperatureAlarm low reading: \(temperatureAlarm(-2))")


// MARK: - ================= DEFENSE QUESTIONS =================
/*
1. guard let vs if let beyond syntax:
   guard let unwraps a value and makes it available in the surrounding scope after the guard.
   Its else block must leave the current scope (for example with return, throw, break, or continue).
   if let unwraps a value only inside the if block. It is useful when the program should continue
   normally after the optional-binding branch.

2. Why can't you pass [Int] to stats(_ values: Int...)?
   A variadic parameter accepts individual Int arguments, for example stats(3, 8, 1).
   An [Int] array is a single array value and Swift does not automatically expand it into
   separate variadic arguments. The array overload stats(of:) accepts [Int] directly.

3. Why doesn't transferOxygen(from: &x, to: &x, amount: 5) compile?
   It would create two simultaneous inout accesses to the same variable. Swift's exclusivity
   rules prevent overlapping mutable access to avoid conflicting reads and writes.

4. Why doesn't oxygenLevel(of: dana) ?? "no data" compile?
   oxygenLevel(of:) returns Int?. The right side of ?? must be compatible with the wrapped type,
   Int, but "no data" is a String. Convert a real level to text or handle the nil case separately,
   for example with if let.

5. Full type of chooseProtocol and how to read it:
   (Int) -> (Int) -> Int, written in its declaration as
   func chooseProtocol(for temp: Int) -> (Int) -> Int.
   It takes a temperature Int and returns a function that itself takes an Int and returns an Int.

Bonus. Where does the alarm counter live after makeAlarm returns?
   alarmCount is a local variable captured by the returned closure. The closure keeps the captured
   state alive after makeAlarm finishes, so repeated calls to the same returned closure share and
   update the same counter. A separate call to makeAlarm creates a separate counter.
*/
