#pragma once

#include <algorithm>
#include <set>
#include <functional>
#include <nlohmann/json.hpp>
#include <iostream>
#include <fstream>

typedef std::function<void(const nlohmann::json &)> Callback;
typedef std::function<nlohmann::json(const nlohmann::json &)> MutateState;

class GlobalProfiler {
    public:
        GlobalProfiler() {
            if (PROFILER_LOG_PATH && logFile.is_open()) {
                logFile << "[\n";
            }
        }
        
        ~GlobalProfiler() {
            if (PROFILER_LOG_PATH && logFile.is_open()) {
                logFile << "\"EOF\"]\n";
            }
        }

        static void registerMutation(MutateState c) {
            _mutations.push_back(c);
        }
        
        static void log() {
            if (PROFILER_LOG_PATH && logFile.is_open()) {
                print(logFile);
            }
        }

        static void mutate() {
            _invocations++;
            for (auto & c : _mutations) {
                _state = c(_state);
            }
            if (DEBUG_PROFILER) print(std::cout);
            log();
        }

        static void registerListener(Callback c) {
            _registered.push_back(c);
        }

        static void print(std::ostream & out) {
            _state["x"] = _invocations;
            out << _state << "," << std::endl;
            _state.erase("x");
        }
        static unsigned PROFILER_INTERVAL;
        static bool DEBUG_PROFILER;
        static nlohmann::json _state;

    private:
        static std::ofstream logFile;
        static const char * PROFILER_LOG_PATH;
        static std::vector<Callback> _registered;
        static std::vector<MutateState> _mutations;
        static uint64_t _invocations;
};