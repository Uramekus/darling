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

#include "PAThreadedMainLoop.h"

PAThreadedMainLoop::PAThreadedMainLoop()
{
	m_mainloop = pa_threaded_mainloop_new();
	if (m_mainloop)
		pa_threaded_mainloop_start(m_mainloop);
}

PAThreadedMainLoop::~PAThreadedMainLoop()
{
	if (m_mainloop)
	{
		pa_threaded_mainloop_stop(m_mainloop);
		pa_threaded_mainloop_free(m_mainloop);
		m_mainloop = nullptr;
	}
}

void PAThreadedMainLoop::lock()
{
	if (m_mainloop)
		pa_threaded_mainloop_lock(m_mainloop);
}

void PAThreadedMainLoop::unlock()
{
	if (m_mainloop)
		pa_threaded_mainloop_unlock(m_mainloop);
}

void PAThreadedMainLoop::wait()
{
	if (m_mainloop)
		pa_threaded_mainloop_wait(m_mainloop);
}

void PAThreadedMainLoop::signal(int accept)
{
	if (m_mainloop)
		pa_threaded_mainloop_signal(m_mainloop, accept);
}

pa_mainloop_api* PAThreadedMainLoop::getAPI()
{
	return m_mainloop ? pa_threaded_mainloop_get_api(m_mainloop) : nullptr;
}
