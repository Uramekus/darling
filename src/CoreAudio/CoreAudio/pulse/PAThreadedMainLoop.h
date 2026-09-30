/*
This file is part of Darling.

Copyright (C) 2026 VibeDarling Project

Darling is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Darling is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Darling.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef PATHREADEDMAINLOOP_H
#define PATHREADEDMAINLOOP_H

#include <pulse/pulseaudio.h>

class PAThreadedMainLoop
{
public:
	PAThreadedMainLoop();
	~PAThreadedMainLoop();

	void lock();
	void unlock();
	void wait();
	void signal(int accept = 0);

	pa_mainloop_api* getAPI();
	pa_threaded_mainloop* get() { return m_mainloop; }

private:
	pa_threaded_mainloop* m_mainloop = nullptr;
};

#endif /* PATHREADEDMAINLOOP_H */
