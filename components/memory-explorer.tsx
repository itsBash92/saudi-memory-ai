"use client";

import { useMemo, useState } from "react";
import { memories, places } from "@/lib/mock-data";

const cities = ["All", ...Array.from(new Set(places.map((place) => place.city)))];

export function MemoryExplorer() {
  const [city, setCity] = useState("All");
  const [selectedPlaceId, setSelectedPlaceId] = useState<string | null>(null);

  const visiblePlaces = useMemo(
    () => places.filter((place) => city === "All" || place.city === city),
    [city],
  );

  const selectedPlace = places.find((place) => place.id === selectedPlaceId);
  const selectedMemory = memories.find((memory) => memory.placeId === selectedPlaceId);

  return (
    <div>
      <div className="filter-row" aria-label="Filter places by city">
        {cities.map((item) => (
          <button
            type="button"
            key={item}
            className={city === item ? "filter-button is-active" : "filter-button"}
            onClick={() => {
              setCity(item);
              setSelectedPlaceId(null);
            }}
            aria-pressed={city === item}
          >
            {item}
          </button>
        ))}
      </div>

      <div className="place-grid">
        {visiblePlaces.map((place) => {
          const memory = memories.find((item) => item.placeId === place.id);
          return (
            <article className={`place-card place-card-${place.accent}`} key={place.id}>
              <div className="place-visual" aria-hidden="true">
                <span className="place-year">{place.era}</span>
                <div className="place-landscape">
                  <i /><i /><i /><i />
                </div>
              </div>
              <div className="place-body">
                <span className="demo-data-badge">Illustrative demo data</span>
                <div className="place-location">
                  <span>{place.city}</span>
                  <span>{Math.round(place.confidence * 100)}% demo score</span>
                </div>
                <h3>{place.name}</h3>
                <p>{place.summary}</p>
                <div className="tag-row">
                  {place.tags.map((tag) => <span key={tag}>{tag}</span>)}
                </div>
                {memory && (
                  <blockquote>
                    “{memory.excerpt}”
                    <footer>{memory.contributor} · circa {memory.approximateYear}</footer>
                  </blockquote>
                )}
                <div className="card-footer">
                  <span>{place.memoriesCount} illustrative memories</span>
                  <button
                    type="button"
                    aria-label={`Open the illustrative memory for ${place.name}`}
                    aria-expanded={selectedPlaceId === place.id}
                    onClick={() => setSelectedPlaceId(place.id)}
                  >
                    Open sample →
                  </button>
                </div>
              </div>
            </article>
          );
        })}
      </div>

      {selectedPlace && selectedMemory && (
        <section
          className="memory-detail"
          aria-live="polite"
          aria-label={`Illustrative memory for ${selectedPlace.name}`}
        >
          <div>
            <span className="demo-data-badge">Illustrative demo · not a historical record</span>
            <p className="memory-detail-location">
              {selectedPlace.region} · circa {selectedMemory.approximateYear}
            </p>
            <h3>{selectedMemory.title}</h3>
            <blockquote>“{selectedMemory.excerpt}”</blockquote>
            <p>
              Sample review state: <strong>{selectedMemory.status.replace("_", " ")}</strong> · {selectedMemory.evidenceCount} sample references.
            </p>
          </div>
          <button
            type="button"
            className="memory-detail-close"
            onClick={() => setSelectedPlaceId(null)}
            aria-label="Close the illustrative memory"
          >
            Close
          </button>
        </section>
      )}
    </div>
  );
}
